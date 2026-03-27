"""
URL Shortener API
─────────────────
Endpoints:
  POST /api/shorten          → Create a short URL
  GET  /api/urls             → List all URLs with click counts
  GET  /api/urls/search?q=   → Search URLs
  GET  /api/<short_code>     → Redirect to the original URL
  DELETE /api/urls/<id>      → Delete a URL
  GET  /api/stats            → Dashboard statistics
  GET  /api/analytics        → Recent click activity
  GET  /api/health           → Health check
"""

import os
import string
import random
import time
from datetime import datetime

from flask import Flask, request, jsonify, redirect
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import redis

# ──────────────────────────────────────────────
# App setup
# ──────────────────────────────────────────────
app = Flask(__name__)
CORS(app)

# Database Configuration (Component-based)
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_HOST = os.environ.get("DB_HOST", "db")
DB_NAME = os.environ.get("DB_NAME", "urlshort")
DB_PORT = os.environ.get("DB_PORT", "5432")

# Safety Check - Fail fast if credentials are missing
if not DB_USER or not DB_PASS:
    print("❌ CRITICAL: DB_USER or DB_PASS not set — API will fail to connect to the database.")

REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

# ── Lazy Redis connection ──────────────────────────────────────────
_cache_client = None

def get_cache():
    """Return a Redis client, connecting lazily so startup never crashes."""
    global _cache_client
    if _cache_client is None:
        try:
            _cache_client = redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=5)
            _cache_client.ping()
        except Exception as e:
            print(f"⚠️  Redis unavailable ({e}). Cache features disabled.")
            _cache_client = None
    return _cache_client

# Track cache stats in memory
cache_stats = {"hits": 0, "misses": 0}
start_time = time.time()

# ──────────────────────────────────────────────
# Database helpers
# ──────────────────────────────────────────────
def get_db():
    """Get a new database connection using individual parameters."""
    return psycopg2.connect(
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME
    )


def init_db():
    """Create the urls table if it doesn't exist."""
    conn = None
    try:
        conn = get_db()
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS urls (
                id         SERIAL PRIMARY KEY,
                short_code VARCHAR(10) UNIQUE NOT NULL,
                original_url TEXT NOT NULL,
                clicks     INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT NOW()
            );
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS url_analytics (
                id         SERIAL PRIMARY KEY,
                short_code VARCHAR(10) NOT NULL,
                clicked_at TIMESTAMP DEFAULT NOW(),
                user_agent TEXT,
                ip_address VARCHAR(45)
            );
        """)
        print("✅ Database initialized")
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
    finally:
        if conn:
            conn.close()


def wait_for_db(max_retries=15, delay=3):
    """Wait for the database to become available."""
    print(f"Connecting to DB: {DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    for attempt in range(max_retries):
        try:
            conn = get_db()
            conn.close()
            print(f"✅ Database connected (attempt {attempt + 1})")
            return
        except Exception as e:
            print(f"⏳ Waiting for database... attempt {attempt + 1}/{max_retries}: {e}")
            time.sleep(delay)
    raise Exception("Could not connect to database")


# ──────────────────────────────────────────────
# Utility
# ──────────────────────────────────────────────
def generate_short_code(length=6):
    """Generate a random short code."""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choices(chars, k=length))


def get_uptime():
    """Return uptime as a human-readable string."""
    elapsed = int(time.time() - start_time)
    hours, remainder = divmod(elapsed, 3600)
    minutes, seconds = divmod(remainder, 60)
    if hours > 0:
        return f"{hours}h {minutes}m {seconds}s"
    elif minutes > 0:
        return f"{minutes}m {seconds}s"
    return f"{seconds}s"


# ──────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────
@app.route("/")
@app.route("/api")
@app.route("/api/")
def welcome():
    """Simple API welcome message for testing."""
    return jsonify({
        "status": "online",
        "message": "SnapLink API is powered up!",
        "version": "1.1.0"
    })


@app.route("/api/health")
def health():
    """Health check — verifies DB and Redis connectivity."""
    status = {"api": "ok"}
    try:
        conn = get_db()
        conn.close()
        status["database"] = "ok"
    except Exception:
        status["database"] = "error"

    c = get_cache()
    if c:
        try:
            c.ping()
            status["redis"] = "ok"
        except Exception:
            status["redis"] = "error"
    else:
        status["redis"] = "error"

    healthy = all(v == "ok" for v in status.values())
    return jsonify(status), (200 if healthy else 503)


@app.route("/api/shorten", methods=["POST"])
def shorten():
    """Create a short URL.
    Returns the real host URL as the short URL base.
    """
    data = request.get_json(silent=True)
    if not data or not data.get("url"):
        return jsonify({"error": "Missing 'url' in request body"}), 400

    original_url = data["url"].strip()
    if not original_url.startswith(("http://", "https://")):
        original_url = "https://" + original_url

    short_code = generate_short_code()

    # Save to PostgreSQL
    conn = get_db()
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO urls (short_code, original_url) VALUES (%s, %s) RETURNING id, created_at",
        (short_code, original_url),
    )
    row = cur.fetchone()
    conn.close()

    # Cache in Redis (expire after 1 hour)
    c = get_cache()
    if c:
        try:
            c.setex(f"url:{short_code}", 3600, original_url)
        except Exception:
            pass

    # Use the actual host from headers for the public URL
    public_host = request.headers.get("X-Forwarded-Host", request.host)
    scheme = request.headers.get("X-Forwarded-Proto", "http")
    
    return jsonify({
        "id": row[0],
        "short_code": short_code,
        "original_url": original_url,
        "short_url": f"{scheme}://{public_host}/api/{short_code}",
        "created_at": row[1].isoformat(),
    }), 201


@app.route("/api/urls")
def list_urls():
    """List all shortened URLs with click counts."""
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SELECT id, short_code, original_url, clicks, created_at FROM urls ORDER BY created_at DESC LIMIT 50")
    rows = cur.fetchall()
    conn.close()

    urls = []
    for row in rows:
        # Check Redis for more up-to-date click count
        c = get_cache()
        cached_clicks = c.get(f"clicks:{row['short_code']}") if c else None
        clicks = int(cached_clicks) if cached_clicks else row["clicks"]
        urls.append({
            "id": row["id"],
            "short_code": row["short_code"],
            "original_url": row["original_url"],
            "clicks": clicks,
            "created_at": row["created_at"].isoformat(),
        })

    return jsonify(urls)


@app.route("/api/urls/search")
def search_urls():
    """Search URLs by original URL or short code."""
    query = request.args.get("q", "").strip()
    if not query:
        return jsonify([])

    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute(
        """SELECT id, short_code, original_url, clicks, created_at
           FROM urls
           WHERE original_url ILIKE %s OR short_code ILIKE %s
           ORDER BY created_at DESC LIMIT 20""",
        (f"%{query}%", f"%{query}%"),
    )
    rows = cur.fetchall()
    conn.close()

    urls = []
    for row in rows:
        c = get_cache()
        cached_clicks = c.get(f"clicks:{row['short_code']}") if c else None
        clicks = int(cached_clicks) if cached_clicks else row["clicks"]
        urls.append({
            "id": row["id"],
            "short_code": row["short_code"],
            "original_url": row["original_url"],
            "clicks": clicks,
            "created_at": row["created_at"].isoformat(),
        })

    return jsonify(urls)


@app.route("/api/urls/<int:url_id>", methods=["DELETE"])
def delete_url(url_id):
    """Delete a URL by its ID."""
    conn = get_db()
    cur = conn.cursor()

    # Get the short_code first to clean up Redis
    cur.execute("SELECT short_code FROM urls WHERE id = %s", (url_id,))
    row = cur.fetchone()

    if not row:
        conn.close()
        return jsonify({"error": "URL not found"}), 404

    short_code = row[0]

    # Delete from DB (analytics cascade deletes)
    cur.execute("DELETE FROM urls WHERE id = %s", (url_id,))
    conn.close()

    # Clean up Redis
    c = get_cache()
    if c:
        try:
            c.delete(f"url:{short_code}")
            c.delete(f"clicks:{short_code}")
        except Exception:
            pass

    return jsonify({"message": "URL deleted", "id": url_id}), 200


@app.route("/api/stats")
def stats():
    """Dashboard statistics."""
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # Total URLs
    cur.execute("SELECT COUNT(*) as total FROM urls")
    total_urls = cur.fetchone()["total"]

    # Total clicks
    cur.execute("SELECT COALESCE(SUM(clicks), 0) as total FROM urls")
    total_clicks = cur.fetchone()["total"]

    # Top 5 URLs
    cur.execute("""
        SELECT short_code, original_url, clicks
        FROM urls ORDER BY clicks DESC LIMIT 5
    """)
    top_urls = cur.fetchall()

    # URLs created today
    cur.execute("SELECT COUNT(*) as today FROM urls WHERE created_at::date = CURRENT_DATE")
    today_count = cur.fetchone()["today"]

    conn.close()

    # Cache stats
    total_cache_ops = cache_stats["hits"] + cache_stats["misses"]
    hit_rate = round((cache_stats["hits"] / total_cache_ops * 100), 1) if total_cache_ops > 0 else 0

    return jsonify({
        "total_urls": total_urls,
        "total_clicks": int(total_clicks),
        "today_urls": today_count,
        "cache_hit_rate": hit_rate,
        "cache_hits": cache_stats["hits"],
        "cache_misses": cache_stats["misses"],
        "uptime": get_uptime(),
        "top_urls": [
            {
                "short_code": u["short_code"],
                "original_url": u["original_url"],
                "clicks": u["clicks"],
            }
            for u in top_urls
        ],
    })


@app.route("/api/analytics")
def analytics():
    """Recent click activity."""
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT a.short_code, a.clicked_at, a.user_agent, a.ip_address, u.original_url
        FROM url_analytics a
        JOIN urls u ON u.short_code = a.short_code
        ORDER BY a.clicked_at DESC LIMIT 30
    """)
    rows = cur.fetchall()
    conn.close()

    return jsonify([
        {
            "short_code": r["short_code"],
            "original_url": r["original_url"],
            "clicked_at": r["clicked_at"].isoformat(),
            "user_agent": r["user_agent"] or "Unknown",
            "ip_address": r["ip_address"] or "Unknown",
        }
        for r in rows
    ])


@app.route("/api/<short_code>")
def redirect_url(short_code):
    """Redirect to the original URL and increment click count."""
    # Try Redis cache first
    c = get_cache()
    original_url = c.get(f"url:{short_code}") if c else None

    if original_url:
        cache_stats["hits"] += 1
    else:
        cache_stats["misses"] += 1
        # Cache miss — fetch from PostgreSQL
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT original_url FROM urls WHERE short_code = %s", (short_code,))
        row = cur.fetchone()
        conn.close()

        if not row:
            return jsonify({"error": "Short URL not found"}), 404

        original_url = row[0]
        # Store in cache for next time
        if c:
            try:
                c.setex(f"url:{short_code}", 3600, original_url)
            except Exception:
                pass

    # Increment click count in Redis (fast, atomic)
    if c:
        try:
            c.incr(f"clicks:{short_code}")
        except Exception:
            pass

    # Update PostgreSQL (clicks + analytics)
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("UPDATE urls SET clicks = clicks + 1 WHERE short_code = %s", (short_code,))

        # Log analytics
        user_agent = request.headers.get("User-Agent", "")[:500]
        ip_address = request.headers.get("X-Forwarded-For", request.remote_addr)
        cur.execute(
            "INSERT INTO url_analytics (short_code, user_agent, ip_address) VALUES (%s, %s, %s)",
            (short_code, user_agent, ip_address),
        )
        conn.close()
    except Exception:
        pass  # Redis has the count, DB will catch up

    return redirect(original_url, code=302)


# ──────────────────────────────────────────────
# Startup
# ──────────────────────────────────────────────
with app.app_context():
    wait_for_db()
    init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

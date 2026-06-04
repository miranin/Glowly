# Database Schema for Glowly Backend

This document defines the complete PostgreSQL database schema for the Glowly application.

## Quick Start

```bash
# Connect to database
psql -U glowly_user -d glowly_db -h localhost

# Copy and paste the schema below
# Or run from file:
psql -U glowly_user -d glowly_db -h localhost -f schema.sql
```

---

## Complete SQL Schema

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS TABLE (Core Authentication)
-- =============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(30) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    profile_photo_url TEXT,
    auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'google', 'apple', 'biometric')),
    is_premium BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_created_at ON users(created_at);

-- =============================================
-- USER PROFILES (Onboarding Data)
-- =============================================
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    has_completed_onboarding BOOLEAN DEFAULT FALSE,

    -- Demographics
    age_range VARCHAR(20) CHECK (age_range IN ('13-17', '18-24', '25-34', '35-44', '45-54', '55+', 'preferNotToSay')),
    sex VARCHAR(20) CHECK (sex IN ('male', 'female', 'nonBinary', 'notSpecified')),

    -- Skin Information
    skin_type VARCHAR(20) CHECK (skin_type IN ('dry', 'oily', 'combination', 'sensitive', 'normal', 'notSpecified')),
    skin_tone VARCHAR(20) CHECK (skin_tone IN ('fair', 'light', 'medium', 'tan', 'deepBrown', 'deepDark', 'notSpecified')),
    skin_conditions TEXT[], -- Array of conditions like ['acne', 'rosacea', 'eczema']

    -- Sensitivities & Allergies
    allergies TEXT[], -- Array of allergens
    sensitivities TEXT[], -- Array of ingredients to avoid

    -- Beauty Preferences
    experience_level VARCHAR(20) CHECK (experience_level IN ('beginner', 'intermediate', 'advanced', 'professional')),
    beauty_goals TEXT[], -- Array like ['hydration', 'antiAging', 'brightening']
    preferred_brands TEXT[], -- Array of brand names
    makeup_frequency VARCHAR(20) CHECK (makeup_frequency IN ('daily', 'frequently', 'occasionally', 'rarely', 'never')),
    skincare_routine_complexity VARCHAR(20) CHECK (skincare_routine_complexity IN ('basic', 'moderate', 'advanced')),
    preferred_product_types TEXT[], -- Array like ['serum', 'moisturizer', 'sunscreen']

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id)
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- =============================================
-- PRODUCTS (Cosmetic Items)
-- =============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Basic Info
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'foundation', 'concealer', 'powder', 'blush', 'bronzer', 'highlighter',
        'eyeshadow', 'eyeliner', 'mascara', 'lipstick', 'lipGloss', 'lipLiner',
        'primer', 'settingSpray', 'cleanser', 'moisturizer', 'serum', 'sunscreen',
        'mask', 'other'
    )),
    application_zone VARCHAR(50) CHECK (application_zone IN (
        'face', 'eyes', 'lips', 'cheeks', 'body', 'hair', 'hands', 'feet', 'nails', 'neck', 'décolletage'
    )),

    -- Purchase & Tracking
    purchase_date DATE,
    expiration_date DATE,
    barcode VARCHAR(50),
    image_url TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,

    -- Product Details
    ingredients TEXT,
    how_to_use TEXT,
    benefits TEXT[], -- Array of benefits
    warnings TEXT[], -- Array of warnings

    -- Safety Flags
    is_sensitive_safe BOOLEAN DEFAULT FALSE,
    is_acne_safe BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_application_zone ON products(application_zone);
CREATE INDEX idx_products_created_at ON products(created_at);
CREATE INDEX idx_products_is_active ON products(is_active);

-- =============================================
-- POSTS (Social Feed)
-- =============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Content
    content TEXT NOT NULL,

    -- Metadata
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,

    -- Visibility
    is_public BOOLEAN DEFAULT TRUE,
    is_premium_content BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_is_public ON posts(is_public);

-- =============================================
-- POST MEDIA (Images/Videos)
-- =============================================
CREATE TABLE post_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,

    -- Media Details
    media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('image', 'video')),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,

    -- Ordering
    display_order INTEGER DEFAULT 0,

    -- Metadata
    width INTEGER,
    height INTEGER,
    duration INTEGER, -- For videos, in seconds
    file_size INTEGER, -- In bytes

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_post_media_post_id ON post_media(post_id);
CREATE INDEX idx_post_media_display_order ON post_media(post_id, display_order);

-- =============================================
-- COMMENTS
-- =============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- For nested replies

    -- Content
    content TEXT NOT NULL,

    -- Metadata
    likes_count INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);

-- =============================================
-- LIKES (For Posts and Comments)
-- =============================================
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Polymorphic relationship
    likeable_type VARCHAR(20) NOT NULL CHECK (likeable_type IN ('post', 'comment')),
    likeable_id UUID NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, likeable_type, likeable_id)
);

CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_likeable ON likes(likeable_type, likeable_id);

-- =============================================
-- WISHLIST
-- =============================================
CREATE TABLE wishlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Product Reference (can be external product not in products table)
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    product_brand VARCHAR(100),
    category VARCHAR(50),
    image_url TEXT,
    external_url TEXT, -- Link to buy the product

    -- Source
    from_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    from_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,

    -- Priority
    priority INTEGER DEFAULT 0,
    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wishlist_user_id ON wishlist_items(user_id);
CREATE INDEX idx_wishlist_product_id ON wishlist_items(product_id);
CREATE INDEX idx_wishlist_created_at ON wishlist_items(created_at);

-- =============================================
-- FOLLOWS (User Relationships)
-- =============================================
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- =============================================
-- OTP CODES (For Email/SMS Verification)
-- =============================================
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- Email or phone number
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(identifier)
);

CREATE INDEX idx_otp_identifier ON otp_codes(identifier);
CREATE INDEX idx_otp_expires_at ON otp_codes(expires_at);

-- =============================================
-- OTP REQUESTS (Rate Limiting)
-- =============================================
CREATE TABLE otp_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_otp_requests_identifier ON otp_requests(identifier, created_at);
CREATE INDEX idx_otp_requests_ip ON otp_requests(ip_address, created_at);

-- =============================================
-- REFRESH TOKENS
-- =============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- =============================================
-- PASSWORD RESET TOKENS
-- =============================================
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_password_reset_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_token ON password_reset_tokens(token);

-- =============================================
-- EMAIL VERIFICATION TOKENS
-- =============================================
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_email_verification_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_token ON email_verification_tokens(token);

-- =============================================
-- NOTIFICATIONS
-- =============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Content
    type VARCHAR(50) NOT NULL CHECK (type IN (
        'like', 'comment', 'follow', 'mention', 'product_expiring', 'system'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,

    -- Related entities
    related_type VARCHAR(20), -- 'post', 'comment', 'user', 'product'
    related_id UUID,

    -- Status
    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- =============================================
-- PREMIUM SUBSCRIPTIONS
-- =============================================
CREATE TABLE premium_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Subscription Details
    subscription_type VARCHAR(20) DEFAULT 'monthly' CHECK (subscription_type IN ('monthly', 'yearly', 'lifetime')),
    price_paid DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',

    -- Status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'refunded')),

    -- Dates
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    cancelled_at TIMESTAMP,

    -- Payment Info (store minimal info, use payment provider for full details)
    payment_provider VARCHAR(50), -- 'stripe', 'apple', 'google'
    payment_provider_subscription_id VARCHAR(255),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_premium_user_id ON premium_subscriptions(user_id);
CREATE INDEX idx_premium_status ON premium_subscriptions(status);
CREATE INDEX idx_premium_expires_at ON premium_subscriptions(expires_at);

-- =============================================
-- TRIGGERS FOR UPDATING updated_at
-- =============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- TRIGGERS FOR UPDATING COUNTS
-- =============================================

-- Update post likes_count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes_count = likes_count + 1
        WHERE id = NEW.likeable_id AND NEW.likeable_type = 'post';
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0)
        WHERE id = OLD.likeable_id AND OLD.likeable_type = 'post';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_likes_count
AFTER INSERT OR DELETE ON likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Update comment likes_count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE comments SET likes_count = likes_count + 1
        WHERE id = NEW.likeable_id AND NEW.likeable_type = 'comment';
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE comments SET likes_count = GREATEST(likes_count - 1, 0)
        WHERE id = OLD.likeable_id AND OLD.likeable_type = 'comment';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_comment_likes_count
AFTER INSERT OR DELETE ON likes
FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- Update post comments_count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comments_count = comments_count + 1
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0)
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_comments_count
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- User feed view (posts from followed users)
CREATE OR REPLACE VIEW user_feed AS
SELECT
    p.*,
    u.username,
    u.name AS user_name,
    u.profile_photo_url AS user_avatar,
    u.is_premium AS user_is_premium
FROM posts p
JOIN users u ON p.user_id = u.id
WHERE p.deleted_at IS NULL
ORDER BY p.created_at DESC;

-- User profile view with stats
CREATE OR REPLACE VIEW user_profiles_with_stats AS
SELECT
    u.id,
    u.username,
    u.name,
    u.profile_photo_url,
    u.is_premium,
    u.created_at,
    (SELECT COUNT(*) FROM posts WHERE user_id = u.id AND deleted_at IS NULL) AS posts_count,
    (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS followers_count,
    (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS following_count
FROM users u
WHERE u.deleted_at IS NULL;

-- =============================================
-- SAMPLE DATA (Optional - for development)
-- =============================================

-- Create a test user
INSERT INTO users (email, username, password_hash, name, auth_provider, is_email_verified)
VALUES
    ('test@glowly.app', 'testuser', '$2b$10$YourHashedPasswordHere', 'Test User', 'email', TRUE);

-- Note: Replace password_hash with actual bcrypt hash of your test password

-- =============================================
-- CLEANUP TASKS (Run periodically)
-- =============================================

-- Delete expired OTP codes (run daily)
DELETE FROM otp_codes WHERE expires_at < NOW() - INTERVAL '1 day';

-- Delete old OTP requests (run weekly)
DELETE FROM otp_requests WHERE created_at < NOW() - INTERVAL '7 days';

-- Delete expired refresh tokens (run daily)
DELETE FROM refresh_tokens WHERE expires_at < NOW();

-- Delete old used password reset tokens (run weekly)
DELETE FROM password_reset_tokens WHERE used = TRUE AND created_at < NOW() - INTERVAL '7 days';
```

---

## Database Relationships

### User-Centric Relationships
```
users
  ├── user_profiles (1:1)
  ├── products (1:N)
  ├── posts (1:N)
  ├── comments (1:N)
  ├── likes (1:N)
  ├── wishlist_items (1:N)
  ├── follows (follower) (1:N)
  ├── follows (following) (1:N)
  ├── premium_subscriptions (1:N)
  ├── notifications (1:N)
  ├── refresh_tokens (1:N)
  └── password_reset_tokens (1:N)
```

### Post-Centric Relationships
```
posts
  ├── post_media (1:N)
  ├── comments (1:N)
  ├── likes (1:N)
  └── user (N:1)
```

### Comment Relationships
```
comments
  ├── likes (1:N)
  ├── replies (parent_comment_id) (1:N)
  ├── post (N:1)
  └── user (N:1)
```

---

## Indexes Rationale

### Performance Indexes
- **users(email, username, phone_number):** Fast login lookups
- **products(user_id, category):** Product browsing and filtering
- **posts(created_at DESC):** Feed pagination
- **comments(post_id, created_at):** Comment loading
- **likes(user_id, likeable_type, likeable_id):** Check if user liked content
- **follows(follower_id, following_id):** Follow/unfollow operations

### Composite Indexes
- **otp_requests(identifier, created_at):** Rate limiting checks
- **post_media(post_id, display_order):** Media ordering
- **notifications(user_id, is_read):** Unread notifications count

---

## Data Integrity Rules

### Soft Deletes
Tables with `deleted_at` column use soft deletes:
- `users`
- `products`
- `posts`
- `comments`

**Implementation:**
```sql
-- Soft delete
UPDATE posts SET deleted_at = CURRENT_TIMESTAMP WHERE id = 'post_id';

-- Queries should filter soft-deleted records
SELECT * FROM posts WHERE deleted_at IS NULL;
```

### Cascading Deletes
- User deletion cascades to all user-owned content
- Post deletion cascades to comments and media
- Comment deletion cascades to replies

---

## Maintenance Queries

### Check Database Size
```sql
SELECT
    pg_size_pretty(pg_database_size('glowly_db')) AS database_size;
```

### Check Table Sizes
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Check Index Usage
```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Vacuum and Analyze (Run weekly)
```sql
VACUUM ANALYZE;
```

---

## Migration Strategy

### Version Control for Schema
Use migration tool like:
- **Node.js:** Sequelize, TypeORM, Knex migrations
- **Python:** Alembic
- **Raw SQL:** Numbered migration files (001_initial.sql, 002_add_premium.sql)

### Example Migration Workflow
```bash
# Create migration
npx sequelize-cli migration:generate --name add-premium-subscriptions

# Run migrations
npx sequelize-cli db:migrate

# Rollback last migration
npx sequelize-cli db:migrate:undo
```

---

## Backup Strategy

### Daily Automated Backup
```bash
#!/bin/bash
# Add to crontab: 0 2 * * * /home/glowly/backup.sh

BACKUP_DIR="/home/glowly/backups"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="glowly_backup_$DATE.sql"

# Create backup
pg_dump -U glowly_user glowly_db > "$BACKUP_DIR/$FILENAME"

# Compress
gzip "$BACKUP_DIR/$FILENAME"

# Delete backups older than 30 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $FILENAME.gz"
```

### Restore from Backup
```bash
# Decompress
gunzip glowly_backup_20240115_020000.sql.gz

# Restore
psql -U glowly_user glowly_db < glowly_backup_20240115_020000.sql
```

---

**Created:** 2024-01-15
**Last Updated:** 2024-01-15
**Database Version:** 1.0

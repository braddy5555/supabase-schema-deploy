-- Cosmic Puppies Initial Schema
-- Migration: 20250211180000

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- LEADS TABLE
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source VARCHAR(255),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),
  industry VARCHAR(100),
  status VARCHAR(50) DEFAULT 'new',
  qualified BOOLEAN DEFAULT false,
  score INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON leads;
CREATE POLICY "Allow public read" ON leads FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert" ON leads;
CREATE POLICY "Allow public insert" ON leads FOR INSERT WITH CHECK (true);

-- ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID REFERENCES leads(id),
  order_number VARCHAR(100) UNIQUE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',
  status VARCHAR(50) DEFAULT 'pending',
  products JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON orders;
CREATE POLICY "Allow public read" ON orders FOR SELECT USING (true);

-- WEBSITE TRAFFIC
CREATE TABLE IF NOT EXISTS traffic (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitors INTEGER DEFAULT 0,
  page_views INTEGER DEFAULT 0,
  unique_visitors INTEGER DEFAULT 0,
  bounce_rate DECIMAL(5,2),
  avg_session_duration INTEGER,
  source VARCHAR(100),
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE traffic ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON traffic;
CREATE POLICY "Allow public read" ON traffic FOR SELECT USING (true);

-- PRODUCTS
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category VARCHAR(100),
  inventory_count INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read" ON products;
CREATE POLICY "Allow public read" ON products FOR SELECT USING (true);

-- FUNNEL STEPS
CREATE TABLE IF NOT EXISTS funnel_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID REFERENCES leads(id),
  step_name VARCHAR(100),
  step_number INTEGER,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE funnel_steps ENABLE ROW LEVEL SECURITY;

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_qualified ON leads(qualified);
CREATE INDEX IF NOT EXISTS idx_leads_created ON leads(created_at);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_traffic_date ON traffic(date);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_leads_updated_at ON leads;
CREATE TRIGGER update_leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- SAMPLE DATA (idempotent)
INSERT INTO leads (source, name, email, company, status, qualified, score) VALUES
  ('linkedin', 'John Doe', 'john@dropship.com', 'Dropship Pro', 'qualified', true, 85),
  ('website', 'Jane Smith', 'jane@shopify.com', 'Shopify Store', 'new', false, 45),
  ('referral', 'Bob Johnson', 'bob@ecom.com', 'Ecom Masters', 'contacted', true, 72),
  ('ads', 'Alice Williams', 'alice@brand.com', 'Brand Co', 'qualified', true, 91)
ON CONFLICT DO NOTHING;

INSERT INTO traffic (visitors, page_views, unique_visitors, bounce_rate, date) VALUES
  (156, 312, 134, 42.5, CURRENT_DATE),
  (203, 456, 189, 38.2, CURRENT_DATE - INTERVAL '1 day'),
  (178, 389, 156, 41.8, CURRENT_DATE - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

INSERT INTO products (name, description, price, category, inventory_count) VALUES
  ('Puppy Starter Pack', 'Everything you need for your new puppy', 49.99, 'essentials', 100),
  ('Cosmic Dog Bed', 'Memory foam bed with galaxy design', 89.99, 'beds', 50),
  ('Star Leash', 'LED illuminated dog leash', 34.99, 'accessories', 200)
ON CONFLICT DO NOTHING;

-- VIEWS
DROP VIEW IF EXISTS daily_metrics;
CREATE VIEW daily_metrics AS
SELECT 
  date,
  COUNT(DISTINCT l.id) as new_leads,
  COUNT(DISTINCT CASE WHEN l.qualified THEN l.id END) as qualified_leads,
  COALESCE(SUM(o.amount), 0) as revenue,
  COUNT(DISTINCT o.id) as orders
FROM traffic t
LEFT JOIN leads l ON DATE(l.created_at) = t.date
LEFT JOIN orders o ON DATE(o.created_at) = t.date
GROUP BY date
ORDER BY date DESC;

-- ENABLE REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE leads;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE traffic;
-- Trigger deployment Wed Feb 11 18:46:54 UTC 2026
-- Deployment triggered Wed Feb 11 18:55:54 UTC 2026
-- Trigger deployment Wed Feb 11 19:00:20 UTC 2026
-- Deployment attempt Wed Feb 11 19:06:55 UTC 2026
-- Debug deployment Wed Feb 11 19:13:15 UTC 2026

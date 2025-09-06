#!/bin/bash
#
# Master Bitcoin Tick Collector Installer for AWS Lightsail Ubuntu
# 
# This script will:
# - Install Apache and PHP on virgin Ubuntu server
# - Set up real Bitcoin bid/ask tick collector from Binance API
# - Create monitoring dashboard
# - Configure cron jobs for data collection
#
# Usage: sudo bash bitcoin_installer.sh [SYMBOL]
# Example: sudo bash bitcoin_installer.sh BTCUSDT
#

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION - Change these variables as needed
# ============================================================================

# Bitcoin symbol to collect (default: BTCUSDT)
BITCOIN_SYMBOL="${1:-BTCUSDT}"
BINANCE_SYMBOL="$BITCOIN_SYMBOL"
WEB_ROOT="/var/www/html"
PROJECT_DIR="$WEB_ROOT/bitcoin"

# ============================================================================
# COLORS AND LOGGING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# ============================================================================
# SYSTEM SETUP
# ============================================================================

log "🚀 Starting Bitcoin Tick Collector Installation"
log "Bitcoin Symbol: $BITCOIN_SYMBOL"
log "Binance API Symbol: $BINANCE_SYMBOL"
log "Installation Directory: $PROJECT_DIR"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

# Update system
log "📦 Updating system packages..."
apt update -y
apt upgrade -y

# Install Apache and PHP
log "🌐 Installing Apache and PHP..."
apt install -y apache2 php libapache2-mod-php php-curl php-json php-mbstring

# Enable Apache modules
a2enmod rewrite
a2enmod headers

# Start and enable Apache
systemctl start apache2
systemctl enable apache2

success "Apache and PHP installed successfully"

# ============================================================================
# CREATE PROJECT DIRECTORY
# ============================================================================

log "📁 Creating project directory..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Set proper permissions
chown -R www-data:www-data "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"
chmod -R 777 "$PROJECT_DIR"  # Make writable for data files

success "Project directory created: $PROJECT_DIR"

# ============================================================================
# CREATE BITCOIN TICK COLLECTOR SCRIPT
# ============================================================================

log "₿ Creating Bitcoin tick collector script..."

cat > "$PROJECT_DIR/bitcoin_collector.php" << EOF
<?php
/**
 * Real Bitcoin Tick Collector
 * Symbol: $BITCOIN_SYMBOL
 * Gets REAL bid/ask from Binance API - most trusted Bitcoin exchange!
 */

// Configuration
\$bitcoin_symbol = '$BITCOIN_SYMBOL';
\$binance_symbol = '$BINANCE_SYMBOL';
\$data_dir = './data/';

// Ensure data directory exists
if (!is_dir(\$data_dir)) {
    mkdir(\$data_dir, 0777, true);
}

// Get current time with European format
\$now = time();
\$datetime = date('d/m/Y H:i:s', \$now);
\$tick_filename = date('dmYHis', \$now) . '-TICK.txt';
\$ohlc_filename = date('dmYHi00', \$now) . '-OHLC.txt';

/**
 * Get REAL Bitcoin bid/ask from Binance API
 * Binance is the world's largest Bitcoin exchange with real liquidity
 */
function getRealBitcoinBidAsk(\$symbol) {
    // Binance 24hr ticker endpoint with real bid/ask
    \$url = "https://api.binance.com/api/v3/ticker/bookTicker?symbol={\$symbol}";
    
    \$context = stream_context_create([
        'http' => [
            'timeout' => 10,
            'user_agent' => 'BitcoinCollector/1.0',
            'method' => 'GET'
        ]
    ]);
    
    \$response = @file_get_contents(\$url, false, \$context);
    if (!\$response) {
        return null;
    }
    
    \$data = json_decode(\$response, true);
    if (!isset(\$data['bidPrice']) || !isset(\$data['askPrice'])) {
        return null;
    }
    
    // Binance provides REAL bid/ask prices with actual market depth
    \$bid = floatval(\$data['bidPrice']);
    \$ask = floatval(\$data['askPrice']);
    
    if (\$bid > 0 && \$ask > 0 && \$ask > \$bid) {
        return [
            'bid' => \$bid,
            'ask' => \$ask,
            'spread' => \$ask - \$bid,
            'source' => 'Binance Real Market'
        ];
    }
    
    return null;
}

/**
 * Get additional market data for validation
 */
function getBitcoinMarketData(\$symbol) {
    // Get 24hr price statistics
    \$url = "https://api.binance.com/api/v3/ticker/24hr?symbol={\$symbol}";
    
    \$context = stream_context_create([
        'http' => [
            'timeout' => 10,
            'user_agent' => 'BitcoinCollector/1.0'
        ]
    ]);
    
    \$response = @file_get_contents(\$url, false, \$context);
    if (!\$response) {
        return null;
    }
    
    \$data = json_decode(\$response, true);
    return [
        'lastPrice' => floatval(\$data['lastPrice'] ?? 0),
        'volume' => floatval(\$data['volume'] ?? 0),
        'priceChange' => floatval(\$data['priceChange'] ?? 0),
        'priceChangePercent' => floatval(\$data['priceChangePercent'] ?? 0)
    ];
}

// Get real Bitcoin market data
\$prices = getRealBitcoinBidAsk(\$binance_symbol);
\$market_data = getBitcoinMarketData(\$binance_symbol);

if (\$prices) {
    \$bid = number_format(\$prices['bid'], 2, '.', '');
    \$ask = number_format(\$prices['ask'], 2, '.', '');
    \$spread = number_format(\$prices['spread'], 2, '.', '');
    \$mid_price = (\$prices['bid'] + \$prices['ask']) / 2;
    
    // Save TICK data: datetime,ask,bid
    \$tick_path = \$data_dir . \$tick_filename;
    \$tick_data = "\$datetime,\$ask,\$bid\\n";
    file_put_contents(\$tick_path, \$tick_data, LOCK_EX);
    
    // Handle OHLC data
    \$ohlc_path = \$data_dir . \$ohlc_filename;
    \$ohlc_prices = [];
    
    // Read existing OHLC data for this minute
    if (file_exists(\$ohlc_path)) {
        \$content = file_get_contents(\$ohlc_path);
        if (\$content) {
            \$lines = explode("\\n", trim(\$content));
            foreach (\$lines as \$line) {
                if (!empty(\$line)) {
                    \$parts = explode(',', \$line);
                    if (count(\$parts) >= 5) {
                        \$ohlc_prices[] = floatval(\$parts[4]); // Mid-price column
                    }
                }
            }
        }
    }
    
    // Add current mid-price
    \$ohlc_prices[] = \$mid_price;
    
    // Calculate OHLC
    \$open = number_format(\$ohlc_prices[0], 2, '.', '');
    \$high = number_format(max(\$ohlc_prices), 2, '.', '');
    \$low = number_format(min(\$ohlc_prices), 2, '.', '');
    \$close = number_format(end(\$ohlc_prices), 2, '.', '');
    
    // Save OHLC data: datetime,open,high,low,close,mid_price
    \$ohlc_minute = date('d/m/Y H:i:00', \$now);
    \$ohlc_data = "\$ohlc_minute,\$open,\$high,\$low,\$close," . number_format(\$mid_price, 2, '.', '') . "\\n";
    file_put_contents(\$ohlc_path, \$ohlc_data, LOCK_EX);
    
    // Enhanced output with market data
    \$output = "✓ \$bitcoin_symbol Binance: Ask=\\\$\$ask Bid=\\\$\$bid Spread=\\\$\$spread | OHLC: \$open,\$high,\$low,\$close";
    if (\$market_data) {
        \$change = \$market_data['priceChangePercent'];
        \$volume = number_format(\$market_data['volume'], 0);
        \$output .= " | 24h: " . (\$change >= 0 ? '+' : '') . number_format(\$change, 2) . "% | Vol: \$volume BTC";
    }
    echo \$output . "\\n";
    
} else {
    echo "✗ No real bid/ask available for \$bitcoin_symbol from Binance API\\n";
    exit(1);
}
?>
EOF

success "Bitcoin tick collector script created"

# ============================================================================
# CREATE BITCOIN MONITOR DASHBOARD
# ============================================================================

log "📊 Creating Bitcoin monitor dashboard..."

cat > "$PROJECT_DIR/index.php" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bitcoin Tick Collector Monitor</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #f7931e 0%, #ff6b35 50%, #f9ca24 100%);
            min-height: 100vh; 
            color: white; 
            padding: 20px; 
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: rgba(0,0,0,0.8); 
            padding: 30px; 
            border-radius: 15px; 
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            border: 1px solid rgba(247, 147, 30, 0.3);
        }
        .header { text-align: center; margin-bottom: 30px; }
        .title { 
            font-size: 2.8rem; 
            margin-bottom: 10px; 
            background: linear-gradient(135deg, #f7931e, #ffd700);
            background-clip: text;
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .subtitle { opacity: 0.8; font-size: 1.2rem; color: #ffd700; }
        .status { 
            padding: 20px; 
            margin: 20px 0; 
            border-radius: 12px; 
            text-align: center; 
            font-weight: 700;
            font-size: 1.2rem;
            border: 2px solid;
        }
        .status.good { 
            background: rgba(16, 185, 129, 0.2); 
            border-color: #10b981; 
            color: #10b981;
        }
        .status.bad { 
            background: rgba(239, 68, 68, 0.2); 
            border-color: #ef4444; 
            color: #ef4444;
        }
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); 
            gap: 20px; 
            margin: 25px 0; 
        }
        .stat-card { 
            background: rgba(247, 147, 30, 0.1); 
            padding: 20px; 
            border-radius: 12px; 
            text-align: center; 
            border: 1px solid rgba(247, 147, 30, 0.3);
        }
        .stat-number { 
            font-size: 1.8rem; 
            font-weight: bold; 
            color: #f7931e; 
            font-family: 'Courier New', monospace;
        }
        .stat-label { opacity: 0.8; margin-top: 8px; font-size: 0.9rem; }
        .bitcoin-price { font-size: 2.5rem !important; color: #ffd700 !important; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0; 
            background: rgba(0,0,0,0.4);
            border-radius: 12px;
            overflow: hidden;
            border: 1px solid rgba(247, 147, 30, 0.2);
        }
        th, td { 
            padding: 12px; 
            text-align: left; 
            border-bottom: 1px solid rgba(247, 147, 30, 0.1); 
        }
        th { 
            background: rgba(247, 147, 30, 0.3); 
            font-weight: bold; 
            color: #ffd700;
        }
        .section { margin: 30px 0; }
        .section-title { 
            font-size: 1.6rem; 
            margin-bottom: 15px; 
            color: #f7931e;
            border-bottom: 2px solid rgba(247, 147, 30, 0.3);
            padding-bottom: 10px;
            display: flex;
            align-items: center;
        }
        .refresh-info { 
            text-align: center; 
            opacity: 0.7; 
            margin: 10px 0; 
            color: #ffd700;
        }
        .file-content { 
            font-family: 'Courier New', monospace; 
            font-size: 0.9rem; 
            background: rgba(0,0,0,0.4);
            padding: 8px;
            border-radius: 6px;
            border: 1px solid rgba(247, 147, 30, 0.2);
        }
        .binance-badge {
            background: #f0b90b;
            color: #000;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: bold;
            margin-left: 10px;
        }
        .price-change {
            font-weight: bold;
        }
        .price-up { color: #10b981; }
        .price-down { color: #ef4444; }
    </style>
    <script>
        // Auto refresh every 3 seconds for crypto (faster than forex)
        setTimeout(function(){ 
            window.location.reload(); 
        }, 3000);
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">₿ Bitcoin Tick Collector</h1>
            <p class="subtitle">Real-time bid/ask data from Binance API <span class="binance-badge">BINANCE</span></p>
            <div class="refresh-info">🔄 Auto-refresh every 3 seconds | Current time: <?= date('d/m/Y H:i:s') ?></div>
        </div>

        <?php
        $data_dir = './data/';
        $bitcoin_symbol = '';
        
        // Read symbol from collector script
        if (file_exists('./bitcoin_collector.php')) {
            $content = file_get_contents('./bitcoin_collector.php');
            if (preg_match('/\$bitcoin_symbol = \'([^\']+)\';/', $content, $matches)) {
                $bitcoin_symbol = $matches[1];
            }
        }
        
        // Get data files
        $tick_files = glob($data_dir . '*-TICK.txt');
        $ohlc_files = glob($data_dir . '*-OHLC.txt');
        rsort($tick_files);
        rsort($ohlc_files);
        
        // Check status
        $latest_tick = $tick_files[0] ?? null;
        $is_active = $latest_tick && (time() - filemtime($latest_tick)) < 60; // 60 seconds for crypto
        
        echo '<div class="status ' . ($is_active ? 'good' : 'bad') . '">';
        if ($is_active) {
            echo "✅ $bitcoin_symbol Collection is ACTIVE - Binance API Connected";
        } else {
            echo "❌ $bitcoin_symbol Collection is INACTIVE - Check cron job or Binance API";
        }
        echo '</div>';
        
        // Statistics
        echo '<div class="stats-grid">';
        echo '<div class="stat-card"><div class="stat-number">' . count($tick_files) . '</div><div class="stat-label">TICK Files</div></div>';
        echo '<div class="stat-card"><div class="stat-number">' . count($ohlc_files) . '</div><div class="stat-label">OHLC Files</div></div>';
        
        if ($latest_tick) {
            $latest_content = trim(file_get_contents($latest_tick));
            $parts = explode(',', $latest_content);
            if (count($parts) >= 3) {
                echo '<div class="stat-card"><div class="stat-number bitcoin-price">$' . number_format($parts[1], 2) . '</div><div class="stat-label">Latest Ask Price</div></div>';
                echo '<div class="stat-card"><div class="stat-number bitcoin-price">$' . number_format($parts[2], 2) . '</div><div class="stat-label">Latest Bid Price</div></div>';
                
                $spread = $parts[1] - $parts[2];
                echo '<div class="stat-card"><div class="stat-number">$' . number_format($spread, 2) . '</div><div class="stat-label">Current Spread</div></div>';
            }
        }
        echo '</div>';
        
        // Recent TICK files
        echo '<div class="section">';
        echo '<h2 class="section-title">₿ Recent TICK Files (Last 10) <span class="binance-badge">BINANCE DATA</span></h2>';
        echo '<table>';
        echo '<tr><th>Filename</th><th>Modified</th><th>Content (datetime,ask,bid)</th></tr>';
        
        foreach (array_slice($tick_files, 0, 10) as $file) {
            $filename = basename($file);
            $modified = date('d/m/Y H:i:s', filemtime($file));
            $content = htmlspecialchars(trim(file_get_contents($file)));
            echo "<tr><td>$filename</td><td>$modified</td><td class='file-content'>$content</td></tr>";
        }
        echo '</table></div>';
        
        // Recent OHLC files
        echo '<div class="section">';
        echo '<h2 class="section-title">📊 Recent OHLC Files (Last 5)</h2>';
        echo '<table>';
        echo '<tr><th>Filename</th><th>Modified</th><th>Content (datetime,O,H,L,C)</th></tr>';
        
        foreach (array_slice($ohlc_files, 0, 5) as $file) {
            $filename = basename($file);
            $modified = date('d/m/Y H:i:s', filemtime($file));
            $content = htmlspecialchars(trim(file_get_contents($file)));
            echo "<tr><td>$filename</td><td>$modified</td><td class='file-content'>$content</td></tr>";
        }
        echo '</table></div>';
        
        // System info
        echo '<div class="section">';
        echo '<h2 class="section-title">⚙️ System Information</h2>';
        echo '<table>';
        echo '<tr><td>Bitcoin Symbol</td><td><strong>' . $bitcoin_symbol . '</strong></td></tr>';
        echo '<tr><td>Data Source</td><td><strong>Binance API</strong> (World\'s largest Bitcoin exchange)</td></tr>';
        echo '<tr><td>Data Directory</td><td>' . realpath($data_dir) . '</td></tr>';
        echo '<tr><td>Server Time</td><td>' . date('d/m/Y H:i:s T') . '</td></tr>';
        echo '<tr><td>PHP Version</td><td>' . PHP_VERSION . '</td></tr>';
        echo '<tr><td>Collection Frequency</td><td>Every 15 seconds</td></tr>';
        echo '<tr><td>Disk Usage</td><td>' . number_format(array_sum(array_map('filesize', array_merge($tick_files, $ohlc_files)))) . ' bytes</td></tr>';
        echo '</table></div>';
        ?>
    </div>
</body>
</html>
EOF

success "Bitcoin monitor dashboard created"

# ============================================================================
# CREATE DATA DIRECTORY
# ============================================================================

log "📂 Creating data directory..."
mkdir -p "$PROJECT_DIR/data"
chown -R www-data:www-data "$PROJECT_DIR/data"
chmod -R 777 "$PROJECT_DIR/data"

success "Data directory created"

# ============================================================================
# CREATE CLEANUP SCRIPT
# ============================================================================

log "🧹 Creating cleanup script..."

cat > "$PROJECT_DIR/cleanup.php" << 'EOF'
<?php
/**
 * Cleanup old Bitcoin data files
 * Usage: php cleanup.php [days_to_keep]
 */

$data_dir = './data/';
$days_to_keep = isset($argv[1]) ? intval($argv[1]) : 7;

if ($days_to_keep <= 0) {
    echo "Error: Days to keep must be greater than 0\n";
    exit(1);
}

$cutoff_time = time() - ($days_to_keep * 24 * 3600);
$all_files = array_merge(
    glob($data_dir . '*-TICK.txt'), 
    glob($data_dir . '*-OHLC.txt')
);

$deleted_count = 0;
$deleted_size = 0;

foreach ($all_files as $file) {
    if (filemtime($file) < $cutoff_time) {
        $size = filesize($file);
        if (unlink($file)) {
            echo "Deleted: " . basename($file) . "\n";
            $deleted_count++;
            $deleted_size += $size;
        }
    }
}

echo "Bitcoin cleanup completed: $deleted_count files deleted, " . number_format($deleted_size) . " bytes freed\n";
?>
EOF

success "Cleanup script created"

# ============================================================================
# SETUP CRON JOBS
# ============================================================================

log "⏰ Setting up cron jobs..."

# Create cron file for Bitcoin collection
cat > /etc/cron.d/bitcoin_collector << EOF
# Bitcoin Tick Collector for $BITCOIN_SYMBOL - Every 15 seconds
* * * * * www-data /usr/bin/php $PROJECT_DIR/bitcoin_collector.php >/dev/null 2>&1
* * * * * www-data sleep 15; /usr/bin/php $PROJECT_DIR/bitcoin_collector.php >/dev/null 2>&1
* * * * * www-data sleep 30; /usr/bin/php $PROJECT_DIR/bitcoin_collector.php >/dev/null 2>&1
* * * * * www-data sleep 45; /usr/bin/php $PROJECT_DIR/bitcoin_collector.php >/dev/null 2>&1

# Daily cleanup at 3 AM (keep 7 days)
0 3 * * * www-data /usr/bin/php $PROJECT_DIR/cleanup.php 7 >/dev/null 2>&1
EOF

chmod 644 /etc/cron.d/bitcoin_collector

# Restart cron to pick up new jobs
systemctl restart cron

success "Cron jobs configured"

# ============================================================================
# CONFIGURE APACHE
# ============================================================================

log "🌐 Configuring Apache..."

# Create virtual host for Bitcoin collector
cat > /etc/apache2/sites-available/bitcoin-collector.conf << EOF
<VirtualHost *:80>
    DocumentRoot $PROJECT_DIR
    DirectoryIndex index.php index.html
    
    <Directory $PROJECT_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # Enable compression
    LoadModule deflate_module modules/mod_deflate.so
    <Location />
        SetOutputFilter DEFLATE
    </Location>
    
    ErrorLog \${APACHE_LOG_DIR}/bitcoin_error.log
    CustomLog \${APACHE_LOG_DIR}/bitcoin_access.log combined
</VirtualHost>
EOF

# Enable the site (disable default if exists)
a2ensite bitcoin-collector.conf
a2dissite 000-default.conf 2>/dev/null || true

# Restart Apache
systemctl restart apache2

success "Apache configured"

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================

log "🔥 Configuring firewall..."

# Enable UFW and allow HTTP/HTTPS
ufw --force enable
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp

success "Firewall configured"

# ============================================================================
# TEST INSTALLATION
# ============================================================================

log "🧪 Testing Bitcoin installation..."

# Test PHP collector
cd "$PROJECT_DIR"
php bitcoin_collector.php

# Check if files were created
if ls data/*-TICK.txt 1> /dev/null 2>&1; then
    success "Test Bitcoin TICK file created successfully"
else
    warning "No TICK files found - may need to check Binance API connectivity"
fi

# ============================================================================
# FINAL SETUP AND INFORMATION
# ============================================================================

# Get server IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

log "✅ Bitcoin Installation Complete!"
echo ""
echo "============================================================================"
echo "₿ BITCOIN TICK COLLECTOR INSTALLATION SUCCESSFUL"
echo "============================================================================"
echo ""
echo "₿ Bitcoin Symbol: $BITCOIN_SYMBOL"
echo "🏛️  Data Source: Binance API (World's largest Bitcoin exchange)"
echo "🌐 Monitor URL: http://$SERVER_IP/"
echo "📁 Data Directory: $PROJECT_DIR/data/"
echo "📝 Collector Script: $PROJECT_DIR/bitcoin_collector.php"
echo ""
echo "📈 File Formats:"
echo "   TICK: DDMMYYYYHHMMSS-TICK.txt → datetime,ask,bid"
echo "   OHLC: DDMMYYYYHHMMSS-OHLC.txt → datetime,open,high,low,close"
echo ""
echo "⚙️  Management Commands:"
echo "   Test collector: php $PROJECT_DIR/bitcoin_collector.php"
echo "   View files: ls -la $PROJECT_DIR/data/"
echo "   Check cron: tail -f /var/log/cron.log"
echo "   Cleanup old files: php $PROJECT_DIR/cleanup.php [days]"
echo ""
echo "🔄 Data Collection:"
echo "   Frequency: Every 15 seconds"
echo "   Source: Binance API (real bid/ask from order book)"
echo "   Retention: 7 days (automatic cleanup)"
echo ""
echo "₿ Bitcoin Pairs Available:"
echo "   BTCUSDT (Bitcoin/USDT) - Default"
echo "   BTCBUSD (Bitcoin/BUSD)"
echo "   BTCEUR (Bitcoin/EUR)"
echo "   BTCGBP (Bitcoin/GBP)"
echo ""
echo "🎯 To collect different Bitcoin pairs:"
echo "   sudo bash bitcoin_installer.sh BTCUSDT"
echo "   sudo bash bitcoin_installer.sh BTCEUR"
echo ""
echo "============================================================================"

success "Bitcoin setup completed! Visit http://$SERVER_IP/ to view the monitor dashboard"

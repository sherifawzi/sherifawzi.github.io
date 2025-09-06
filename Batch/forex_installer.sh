#!/bin/bash
#
# Master Forex Tick Collector Installer for AWS Lightsail Ubuntu
# 
# This script will:
# - Install Apache and PHP on virgin Ubuntu server
# - Set up real bid/ask tick collector from Yahoo Finance
# - Create monitoring dashboard
# - Configure cron jobs for data collection
#
# Usage: sudo bash forex_installer.sh [CURRENCY_PAIR]
# Example: sudo bash forex_installer.sh GBPUSD
#

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION - Change these variables as needed
# ============================================================================

# Currency pair to collect (default: EURUSD)
CURRENCY_PAIR="${1:-EURUSD}"
YAHOO_SYMBOL="${CURRENCY_PAIR}=X"
WEB_ROOT="/var/www/html"
PROJECT_DIR="$WEB_ROOT/forex"

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

log "🚀 Starting Forex Tick Collector Installation"
log "Currency Pair: $CURRENCY_PAIR"
log "Yahoo Symbol: $YAHOO_SYMBOL"
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
apt install -y apache2 php libapache2-mod-php php-curl php-json

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
# CREATE TICK COLLECTOR SCRIPT
# ============================================================================

log "📝 Creating tick collector script..."

cat > "$PROJECT_DIR/tick_collector.php" << EOF
<?php
/**
 * Real Forex Tick Collector
 * Currency: $CURRENCY_PAIR
 * Gets REAL bid/ask from Yahoo Finance - no fake spreads!
 */

// Configuration
\$currency_pair = '$CURRENCY_PAIR';
\$yahoo_symbol = '$YAHOO_SYMBOL';
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
 * Get REAL bid/ask from Yahoo Finance
 */
function getRealBidAsk(\$symbol) {
    \$url = "https://query1.finance.yahoo.com/v7/finance/quote?symbols={\$symbol}&fields=bid,ask,regularMarketPrice";
    
    \$context = stream_context_create([
        'http' => [
            'timeout' => 10,
            'user_agent' => 'Mozilla/5.0 (compatible; ForexCollector/1.0)',
            'method' => 'GET'
        ]
    ]);
    
    \$response = @file_get_contents(\$url, false, \$context);
    if (!\$response) {
        return null;
    }
    
    \$data = json_decode(\$response, true);
    if (!isset(\$data['quoteResponse']['result'][0])) {
        return null;
    }
    
    \$quote = \$data['quoteResponse']['result'][0];
    
    // Only return if we have REAL bid and ask prices
    if (isset(\$quote['bid']) && isset(\$quote['ask']) && 
        \$quote['bid'] > 0 && \$quote['ask'] > 0) {
        return [
            'bid' => floatval(\$quote['bid']),
            'ask' => floatval(\$quote['ask']),
            'source' => 'real'
        ];
    }
    
    // If no real bid/ask but we have market price, return null (no fake calculation!)
    return null;
}

// Get real market data
\$prices = getRealBidAsk(\$yahoo_symbol);

if (\$prices) {
    \$bid = number_format(\$prices['bid'], 5, '.', '');
    \$ask = number_format(\$prices['ask'], 5, '.', '');
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
    \$open = number_format(\$ohlc_prices[0], 5, '.', '');
    \$high = number_format(max(\$ohlc_prices), 5, '.', '');
    \$low = number_format(min(\$ohlc_prices), 5, '.', '');
    \$close = number_format(end(\$ohlc_prices), 5, '.', '');
    
    // Save OHLC data: datetime,open,high,low,close,mid_price
    \$ohlc_minute = date('d/m/Y H:i:00', \$now);
    \$ohlc_data = "\$ohlc_minute,\$open,\$high,\$low,\$close," . number_format(\$mid_price, 5, '.', '') . "\\n";
    file_put_contents(\$ohlc_path, \$ohlc_data, LOCK_EX);
    
    echo "✓ \$currency_pair Real: Ask=\$ask Bid=\$bid | OHLC: \$open,\$high,\$low,\$close\\n";
    
} else {
    echo "✗ No real bid/ask available for \$currency_pair from Yahoo Finance\\n";
    exit(1);
}
?>
EOF

success "Tick collector script created"

# ============================================================================
# CREATE MONITOR DASHBOARD
# ============================================================================

log "📊 Creating monitor dashboard..."

cat > "$PROJECT_DIR/index.php" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forex Tick Collector Monitor</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; 
            color: white; 
            padding: 20px; 
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1); 
            padding: 30px; 
            border-radius: 15px; 
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .header { text-align: center; margin-bottom: 30px; }
        .title { font-size: 2.5rem; margin-bottom: 10px; }
        .subtitle { opacity: 0.8; font-size: 1.1rem; }
        .status { 
            padding: 15px; 
            margin: 20px 0; 
            border-radius: 10px; 
            text-align: center; 
            font-weight: 600;
            font-size: 1.1rem;
        }
        .status.good { background: rgba(76, 175, 80, 0.3); border: 2px solid #4CAF50; }
        .status.bad { background: rgba(244, 67, 54, 0.3); border: 2px solid #F44336; }
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin: 20px 0; 
        }
        .stat-card { 
            background: rgba(255,255,255,0.1); 
            padding: 20px; 
            border-radius: 10px; 
            text-align: center; 
        }
        .stat-number { font-size: 2rem; font-weight: bold; color: #FFD700; }
        .stat-label { opacity: 0.8; margin-top: 5px; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0; 
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            overflow: hidden;
        }
        th, td { 
            padding: 12px; 
            text-align: left; 
            border-bottom: 1px solid rgba(255,255,255,0.1); 
        }
        th { 
            background: rgba(255,255,255,0.2); 
            font-weight: bold; 
            color: #FFD700;
        }
        .section { margin: 30px 0; }
        .section-title { 
            font-size: 1.5rem; 
            margin-bottom: 15px; 
            color: #FFD700;
            border-bottom: 2px solid rgba(255,255,255,0.2);
            padding-bottom: 10px;
        }
        .refresh-info { 
            text-align: center; 
            opacity: 0.7; 
            margin: 10px 0; 
        }
        .file-content { 
            font-family: 'Courier New', monospace; 
            font-size: 0.9rem; 
            background: rgba(0,0,0,0.2);
            padding: 5px;
            border-radius: 3px;
        }
    </style>
    <script>
        // Auto refresh every 5 seconds
        setTimeout(function(){ 
            window.location.reload(); 
        }, 5000);
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">📈 Forex Tick Collector</h1>
            <p class="subtitle">Real-time bid/ask data collection from Yahoo Finance</p>
            <div class="refresh-info">🔄 Auto-refresh every 5 seconds | Current time: <?= date('d/m/Y H:i:s') ?></div>
        </div>

        <?php
        $data_dir = './data/';
        $currency_pair = '';
        
        // Read currency from collector script
        if (file_exists('./tick_collector.php')) {
            $content = file_get_contents('./tick_collector.php');
            if (preg_match('/\$currency_pair = \'([^\']+)\';/', $content, $matches)) {
                $currency_pair = $matches[1];
            }
        }
        
        // Get data files
        $tick_files = glob($data_dir . '*-TICK.txt');
        $ohlc_files = glob($data_dir . '*-OHLC.txt');
        rsort($tick_files);
        rsort($ohlc_files);
        
        // Check status
        $latest_tick = $tick_files[0] ?? null;
        $is_active = $latest_tick && (time() - filemtime($latest_tick)) < 120;
        
        echo '<div class="status ' . ($is_active ? 'good' : 'bad') . '">';
        if ($is_active) {
            echo "✅ $currency_pair Collection is ACTIVE";
        } else {
            echo "❌ $currency_pair Collection is INACTIVE - Check cron job";
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
                echo '<div class="stat-card"><div class="stat-number">' . $parts[1] . '</div><div class="stat-label">Latest Ask</div></div>';
                echo '<div class="stat-card"><div class="stat-number">' . $parts[2] . '</div><div class="stat-label">Latest Bid</div></div>';
            }
        }
        echo '</div>';
        
        // Recent TICK files
        echo '<div class="section">';
        echo '<h2 class="section-title">Recent TICK Files (Last 10)</h2>';
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
        echo '<h2 class="section-title">Recent OHLC Files (Last 5)</h2>';
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
        echo '<h2 class="section-title">System Information</h2>';
        echo '<table>';
        echo '<tr><td>Currency Pair</td><td>' . $currency_pair . '</td></tr>';
        echo '<tr><td>Data Directory</td><td>' . realpath($data_dir) . '</td></tr>';
        echo '<tr><td>Server Time</td><td>' . date('d/m/Y H:i:s T') . '</td></tr>';
        echo '<tr><td>PHP Version</td><td>' . PHP_VERSION . '</td></tr>';
        echo '<tr><td>Disk Usage</td><td>' . number_format(array_sum(array_map('filesize', array_merge($tick_files, $ohlc_files)))) . ' bytes</td></tr>';
        echo '</table></div>';
        ?>
    </div>
</body>
</html>
EOF

success "Monitor dashboard created"

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
 * Cleanup old forex data files
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

echo "Cleanup completed: $deleted_count files deleted, " . number_format($deleted_size) . " bytes freed\n";
?>
EOF

success "Cleanup script created"

# ============================================================================
# SETUP CRON JOBS
# ============================================================================

log "⏰ Setting up cron jobs..."

# Create cron file for forex collection
cat > /etc/cron.d/forex_collector << EOF
# Forex Tick Collector for $CURRENCY_PAIR - Every 15 seconds
* * * * * www-data /usr/bin/php $PROJECT_DIR/tick_collector.php >/dev/null 2>&1
* * * * * www-data sleep 15; /usr/bin/php $PROJECT_DIR/tick_collector.php >/dev/null 2>&1
* * * * * www-data sleep 30; /usr/bin/php $PROJECT_DIR/tick_collector.php >/dev/null 2>&1
* * * * * www-data sleep 45; /usr/bin/php $PROJECT_DIR/tick_collector.php >/dev/null 2>&1

# Daily cleanup at 2 AM (keep 7 days)
0 2 * * * www-data /usr/bin/php $PROJECT_DIR/cleanup.php 7 >/dev/null 2>&1
EOF

chmod 644 /etc/cron.d/forex_collector

# Restart cron to pick up new jobs
systemctl restart cron

success "Cron jobs configured"

# ============================================================================
# CONFIGURE APACHE
# ============================================================================

log "🌐 Configuring Apache..."

# Create virtual host for forex collector
cat > /etc/apache2/sites-available/forex-collector.conf << EOF
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
    
    ErrorLog \${APACHE_LOG_DIR}/forex_error.log
    CustomLog \${APACHE_LOG_DIR}/forex_access.log combined
</VirtualHost>
EOF

# Enable the site
a2ensite forex-collector.conf
a2dissite 000-default.conf

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

log "🧪 Testing installation..."

# Test PHP collector
cd "$PROJECT_DIR"
php tick_collector.php

# Check if files were created
if ls data/*-TICK.txt 1> /dev/null 2>&1; then
    success "Test TICK file created successfully"
else
    warning "No TICK files found - may need to check Yahoo Finance connectivity"
fi

# ============================================================================
# FINAL SETUP AND INFORMATION
# ============================================================================

# Get server IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

log "✅ Installation Complete!"
echo ""
echo "============================================================================"
echo "🎉 FOREX TICK COLLECTOR INSTALLATION SUCCESSFUL"
echo "============================================================================"
echo ""
echo "📊 Currency Pair: $CURRENCY_PAIR"
echo "🌐 Monitor URL: http://$SERVER_IP/"
echo "📁 Data Directory: $PROJECT_DIR/data/"
echo "📝 Collector Script: $PROJECT_DIR/tick_collector.php"
echo ""
echo "📈 File Formats:"
echo "   TICK: DDMMYYYYHHMMSS-TICK.txt → datetime,ask,bid"
echo "   OHLC: DDMMYYYYHHMMSS-OHLC.txt → datetime,open,high,low,close"
echo ""
echo "⚙️  Management Commands:"
echo "   Test collector: php $PROJECT_DIR/tick_collector.php"
echo "   View files: ls -la $PROJECT_DIR/data/"
echo "   Check cron: tail -f /var/log/cron.log"
echo "   Cleanup old files: php $PROJECT_DIR/cleanup.php [days]"
echo ""
echo "🔄 Data Collection:"
echo "   Frequency: Every 15 seconds"
echo "   Source: Yahoo Finance (real bid/ask only)"
echo "   Retention: 7 days (automatic cleanup)"
echo ""
echo "🎯 To collect different currency pairs:"
echo "   1. Change CURRENCY_PAIR variable at top of this script"
echo "   2. Re-run: sudo bash forex_installer.sh GBPUSD"
echo ""
echo "============================================================================"

success "Setup completed! Visit http://$SERVER_IP/ to view the monitor dashboard"

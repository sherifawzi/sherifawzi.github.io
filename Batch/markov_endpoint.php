<?php
// ============================================================
// FULLY CORRECTED MARKOV ENDPOINT
// ============================================================

// Log file for debugging
$logFile = '/tmp/markov_debug.log';

// --- HANDLE POST REQUESTS (from your MQL5 bots) ---
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Log the raw input for debugging
    $rawInput = file_get_contents('php://input');
    file_put_contents($logFile, date('Y-m-d H:i:s') . " RAW POST: " . $rawInput . "\n", FILE_APPEND);

    // Set JSON header for API responses
    header('Content-Type: application/json');

    // Try to decode JSON
    $input = json_decode($rawInput, true);
    if (!$input) {
        file_put_contents($logFile, date('Y-m-d H:i:s') . " ERROR: Invalid JSON\n", FILE_APPEND);
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON', 'received' => $rawInput]);
        exit;
    }

    // Extract fields
    $symbol     = isset($input['symbol']) ? trim($input['symbol']) : '';
    $timeframe  = isset($input['timeframe']) ? trim($input['timeframe']) : '';
    $timestamp  = isset($input['timestamp']) ? (int)$input['timestamp'] : 0;
    $prediction = isset($input['prediction']) ? strtoupper(trim($input['prediction'])) : '';
    $confidence = isset($input['confidence']) ? floatval($input['confidence']) : null;
    $correct    = isset($input['correct']) ? filter_var($input['correct'], FILTER_VALIDATE_BOOLEAN) : null;

    // Validate required fields
    if (!$symbol || !$timeframe || !$timestamp || !$prediction || $confidence === null) {
        file_put_contents($logFile, date('Y-m-d H:i:s') . " ERROR: Missing fields\n", FILE_APPEND);
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields', 'received' => $input]);
        exit;
    }

    // Database connection
    $host = 'localhost';
    $db   = 'markov_bias';
    $user = 'markov_user';
    $pass = 'YourStrongPassword123!';  // <-- CHANGE THIS PASSWORD

    try {
        $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        file_put_contents($logFile, date('Y-m-d H:i:s') . " DB ERROR: " . $e->getMessage() . "\n", FILE_APPEND);
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed']);
        exit;
    }

    $candle_time = date('Y-m-d H:i:s', $timestamp);
    $direction = ($prediction === 'HIGHER') ? 'HIGHER' : 'LOWER';

    // Handle outcome update (when 'correct' flag is present)
    if ($correct !== null) {
        $stmt = $pdo->prepare("UPDATE predictions SET was_correct = ?, actual_direction = ? WHERE symbol = ? AND timeframe = ? AND candle_time = ?");
        $stmt->execute([$correct ? 1 : 0, $direction, $symbol, $timeframe, $candle_time]);
        file_put_contents($logFile, date('Y-m-d H:i:s') . " UPDATED: $symbol $timeframe $candle_time\n", FILE_APPEND);
        echo json_encode(['status' => 'updated']);
        exit;
    }

    // Insert new prediction
    $stmt = $pdo->prepare("INSERT INTO predictions (symbol, timeframe, candle_time, predicted_direction, confidence) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$symbol, $timeframe, $candle_time, $direction, $confidence]);
    $newId = $pdo->lastInsertId();
    file_put_contents($logFile, date('Y-m-d H:i:s') . " INSERTED: $symbol $timeframe confidence=$confidence% id=$newId\n", FILE_APPEND);
    echo json_encode(['status' => 'inserted', 'id' => $newId]);
    exit;
}

// --- HANDLE GET REQUESTS (the dashboard you see in your browser) ---
// This is the code that runs when you visit the URL.
header('Content-Type: text/html; charset=utf-8');

// Database connection (using the same credentials)
try {
    $pdo = new PDO("mysql:host=localhost;dbname=markov_bias;charset=utf8mb4", 'markov_user', 'YourStrongPassword123!');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}

// Fetch the latest prediction for each symbol/timeframe
$stmt = $pdo->query("
    SELECT p1.symbol, p1.timeframe, p1.predicted_direction, p1.confidence, p1.candle_time
    FROM predictions p1
    INNER JOIN (
        SELECT symbol, timeframe, MAX(candle_time) as latest_time
        FROM predictions
        GROUP BY symbol, timeframe
    ) p2 ON p1.symbol = p2.symbol AND p1.timeframe = p2.timeframe AND p1.candle_time = p2.latest_time
    ORDER BY p1.symbol, p1.timeframe
");
$activeBots = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Markov Predictor Dashboard</title>
    <style>
        body { font-family: monospace; background: #0a0c15; color: #e2e8f0; padding: 20px; }
        h1 { color: #10b981; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #334155; padding: 8px; text-align: left; }
        th { background: #1e293b; }
        .up { color: #10b981; }
        .down { color: #ef4444; }
    </style>
</head>
<body>
    <h1>Markov Predictor Dashboard</h1>
    <p><strong>Total active bots:</strong> <?= count($activeBots) ?></p>
    <table>
        <thead>
            <tr><th>Symbol</th><th>Timeframe</th><th>Prediction</th><th>Confidence</th><th>Candle Time (UTC)</th></tr>
        </thead>
        <tbody>
            <?php foreach ($activeBots as $bot): ?>
            <tr>
                <td><?= htmlspecialchars($bot['symbol']) ?></td>
                <td><?= htmlspecialchars($bot['timeframe']) ?></td>
                <td class="<?= strtolower($bot['predicted_direction']) ?>">
                    <?= $bot['predicted_direction'] === 'HIGHER' ? '^ HIGHER' : 'v LOWER' ?>
                </td>
                <td><?= round($bot['confidence'], 1) ?>%</td>
                <td><?= htmlspecialchars($bot['candle_time']) ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
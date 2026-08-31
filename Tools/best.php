<?php
/**
 * SNRC Best-Config-Per-Symbol page generator (schema v07).
 *
 * Reads the same results dump the Results Analyzer loads, computes every
 * metric (including the derived Gain%, Profit/DD, Profit^2/DD and the two
 * cross-row composite scores SNR and Claude), then for each metric picks the
 * single best result per symbol (highest wins, except DD% where lowest wins)
 * and writes a tabbed static HTML page.
 *
 * Intended to run once at the top of every hour from cron, e.g.:
 *   0 * * * * /usr/bin/php /var/www/html/SNRC/TestResults/BestConfigStringFinder.php >> /var/log/snr_bestcfg.log 2>&1
 *
 * No client-side JS does any data work: everything is baked into the HTML.
 */

// --- Config -------------------------------------------------------------------
// Same filename the analyzer's textbox defaults to. Adjust to taste; a '.txt'
// suffix is appended automatically if missing, mirroring the analyzer.
$RESULTS_FILE = '/var/data/SNRC/TestResults/snrv07_50k_500.txt';
$OUTPUT_FILE  = __DIR__ . '/beststrings.php';
$VERSION      = 'v07';

// Prepended to the generated page so it sits behind the admin SSO gate.
// Because it is added at write-time (not inside the heredoc) it can never get
// HTML-escaped, and it lands on line 1 before any output so the guard's
// redirect header always fires cleanly.
$SSO_GUARD_LINE = "<?php require '/var/data/admin/sso_guard.php'; ?>\n";

// 0 * * * * /usr/bin/php /var/www/SNRC/TestResults/BestConfigStringFinder.php >> /var/log/snr_bestcfg.log 2>&1

// --- Change-report settings ---------------------------------------------------
// After each run the winning config per (symbol, metric) is written to
// $STATE_FILE. On the next run the fresh winners are diffed against it and a
// Telegram message goes out ONLY if a different config string took the crown.
//
// "Changed" deliberately means the winning CONFIG STRING changed, not the
// metric value. Backtest values drift on every re-run even when the same
// config still wins, so diffing on value would ping you every single hour.
$STATE_FILE = __DIR__ . '/best_state.json';

// Paste the bot token and channel/chat ID you use for the other SNRC projects.
// Leave $TELEGRAM_TOKEN empty to disable sending (report prints to stdout,
// which still lands in the cron log).
$TELEGRAM_TOKEN   = '8663510120:AAFGc3-F3mk5prPiFD3YEoFXdKnkGeO7H88';
$TELEGRAM_CHAT_ID = '-1003912788760';

// Set true to always send a report even when nothing changed (useful while
// you're confirming delivery actually works).
$ALWAYS_SEND = false;

if (!preg_match('/\.txt$/i', $RESULTS_FILE)) {
    $RESULTS_FILE .= '.txt';
}

// --- v07 config-string decoder ------------------------------------------------
// After splitting a config string on '|':
//   raw[0]=''  raw[1]='sos'  raw[2]=version  raw[3]=first field
// Indices below are absolute positions in that raw array.
$DECODER_ENUMS = [
    'HedgeExpandMode'  => [0 => 'Flat',           1 => 'Stepped',          2 => 'Linear'],
    'DoubleModes'      => [0 => 'NoDouble',       1 => 'Simple',           2 => 'Extended'],
    'TakeProfitMode'   => [0 => 'Standard',       1 => 'Quick',            2 => 'QuickMulti'],
    'TakeProfitMethod' => [0 => 'TakeProfitFull', 1 => 'TakeProfitPartial'],
];

$CONFIG_FIELDS = [
    ['index' => 3,  'label' => 'Static Lot Size',      'type' => 'boolean'],
    ['index' => 4,  'label' => 'Scaling Amount',        'type' => 'int'],
    ['index' => 5,  'label' => 'Amount Per Min Lot',    'type' => 'int'],
    ['index' => 6,  'label' => 'Seconds Between Trades', 'type' => 'int'],
    ['index' => 7,  'label' => 'Percent of Day',        'type' => 'int'],
    ['index' => 8,  'label' => 'Hedge Expand Mode',     'type' => 'enum', 'enum' => 'HedgeExpandMode'],
    ['index' => 9,  'label' => 'Doubledown Mode',       'type' => 'enum', 'enum' => 'DoubleModes'],
    ['index' => 10, 'label' => 'Doubledown Factor',     'type' => 'double'],
    ['index' => 11, 'label' => 'Take Profit Mode',      'type' => 'enum', 'enum' => 'TakeProfitMode'],
    ['index' => 12, 'label' => 'Take Profit Method',    'type' => 'enum', 'enum' => 'TakeProfitMethod'],
    ['index' => 13, 'label' => 'Take Profit Max',       'type' => 'double'],
    ['index' => 14, 'label' => 'Take Profit Mid',       'type' => 'double'],
    ['index' => 15, 'label' => 'Take Profit Min',       'type' => 'double'],
    ['index' => 16, 'label' => 'Trade Count Mid',       'type' => 'int'],
    ['index' => 17, 'label' => 'Trade Count Min',       'type' => 'int'],
    ['index' => 18, 'label' => 'Margin Mid',            'type' => 'int'],
    ['index' => 19, 'label' => 'Margin Min',            'type' => 'int'],
    ['index' => 20, 'label' => 'Drawdown Mid',          'type' => 'int'],
    ['index' => 21, 'label' => 'Drawdown Min',          'type' => 'int'],
    ['index' => 22, 'label' => 'Age Hours Mid',         'type' => 'int'],
    ['index' => 23, 'label' => 'Age Hours Min',         'type' => 'int'],
    ['index' => 24, 'label' => 'Drawdown Cutoff',       'type' => 'int'],
    ['index' => 25, 'label' => 'Drawdown Buffer',       'type' => 'double'],
    ['index' => 26, 'label' => 'Margin Cutoff',         'type' => 'int'],
    ['index' => 27, 'label' => 'Margin Buffer',         'type' => 'int'],
    ['index' => 28, 'label' => 'Age Mid Factor',        'type' => 'int'],
    ['index' => 29, 'label' => 'Age Min Factor',        'type' => 'int'],
    ['index' => 30, 'label' => 'Min Vote Count',        'type' => 'int'],
    ['index' => 31, 'label' => 'Allow Conflict',        'type' => 'boolean'],
];

// Config strings expire this many days after the test RUN date (the second date
// in the embedded "start-end-size" token, e.g. 2024.01.13-2026.07.13-50k -> run
// date 2026.07.13). Rows past this window are parsed but excluded from analysis.
$EXPIRY_DAYS = 90;

// A config string is only used in the best-criteria calculations if it still has
// at least this many days left before expiring. Effectively shifts the usable
// cutoff to run date + ($EXPIRY_DAYS - $MIN_DAYS_LEFT).
$MIN_DAYS_LEFT = 30;

/**
 * Extract the test run date (YYYY.MM.DD) from a config string. The date token
 * looks like "2024.01.13-2026.07.13-50k"; the run date is the SECOND date.
 * Returns a DateTime at midnight, or null if no such token is found.
 */
function configRunDate($s) {
    if (!preg_match('/(\d{4}\.\d{2}\.\d{2})-(\d{4}\.\d{2}\.\d{2})/', (string)$s, $m)) {
        return null;
    }
    $d = DateTime::createFromFormat('Y.m.d', $m[2]);
    if ($d === false) return null;
    $d->setTime(0, 0, 0);
    return $d;
}

/**
 * True if the config string does NOT have at least $minDaysLeft days remaining
 * before its expiry (run date + $expiryDays). Strings this returns true for are
 * excluded from the best-criteria calculations.
 */
function isConfigExpired($s, $expiryDays, $minDaysLeft = 0) {
    $run = configRunDate($s);
    if ($run === null) return false;   // no date token -> never expire
    $usableDays = $expiryDays - $minDaysLeft;
    $cutoff = (clone $run)->modify("+{$usableDays} days");
    $today = new DateTime('today');
    return $cutoff < $today;
}

function isV07Config($s, $version) {
    if (!$s || $s[0] !== '|') return false;
    $raw = explode('|', $s);
    return isset($raw[1], $raw[2]) && $raw[1] === 'sos' && $raw[2] === $version;
}

function configParts($s, $version) {
    if (!isV07Config($s, $version)) return null;
    $raw = explode('|', $s);
    $eos = array_search('eos', $raw, true);
    return $eos !== false ? array_slice($raw, 0, $eos) : $raw;
}

function decodeConfigValue($field, $value, $enums) {
    if ($field['type'] === 'boolean') return $value === 'true' ? 'True' : 'False';
    if ($value === null || $value === '') $value = '0';
    if ($field['type'] === 'enum' && isset($field['enum'])
        && isset($enums[$field['enum']][$value])) {
        return $enums[$field['enum']][$value];
    }
    if ($field['type'] === 'double') {
        return is_numeric($value) ? number_format((float)$value, 2, '.', '') : $value;
    }
    return $value;
}

/** Decode a whole config string to a label=>value map for display. */
function decodeConfigMap($s, $fields, $enums, $version) {
    $parts = configParts($s, $version);
    $out = [];
    foreach ($fields as $f) {
        $raw = ($parts !== null && isset($parts[$f['index']])) ? $parts[$f['index']] : null;
        $out[$f['label']] = $parts === null ? '' : decodeConfigValue($f, $raw, $enums);
    }
    return $out;
}

// --- Parse the results file ---------------------------------------------------
// Mirrors parseAndDisplayData() in resultanalyzer.html:
//   parts[1]=Result parts[2]=Profit parts[3]=Payoff parts[4]=PF parts[5]=RF
//   parts[6]=SR parts[7]=DD% parts[8]=Trades parts[9]=Lots parts[10]=Config
//   parts[11]=Symbol parts[12]=Broker
// Test date is tracked from "Test Start:" header lines. No filtering applied.
function parseResults($content, $expiryDays, $minDaysLeft = 0, &$stats = null) {
    $lines = preg_split('/\r?\n/', $content);
    $rows = [];
    $currentDate = 'Unknown Date';
    $read = 0;      // valid data rows encountered
    $expired = 0;   // valid rows dropped because their config string expired

    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '') continue;

        if (strpos($line, 'Test Start:') !== false) {
            if (preg_match('/(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})/', $line, $m)) {
                $currentDate = $m[1];
            }
            continue;
        }

        if (!preg_match('/^\d+,[\d\.]/', $line)) continue;

        // Same field splitter the analyzer uses: unquoted runs or quoted spans.
        preg_match_all('/(?:[^,"]+|"[^"]*")+/', $line, $mm);
        $parts = $mm[0];
        if (count($parts) < 13) continue;

        $read++;

        // Expiry filter: drop rows whose config string has fewer than
        // $minDaysLeft days remaining before its run date + $expiryDays expiry.
        if (isConfigExpired($parts[10], $expiryDays, $minDaysLeft)) {
            $expired++;
            continue;
        }

        $result = (float)$parts[1];
        $profit = (float)$parts[2];
        $dd     = (float)$parts[7];

        $initialCapital = $result - $profit;
        $gain = ($initialCapital != 0) ? ($profit / $initialCapital) * 100 : 0.0;

        $profitDD  = ($dd != 0) ? $profit / $dd : 0.0;
        $profit2DD = ($dd != 0) ? ($profit * $profit) / $dd : 0.0;

        $rows[] = [
            'order'     => count($rows),
            'date'      => $currentDate,
            'result'    => $result,
            'profit'    => $profit,
            'gain'      => $gain,
            'payoff'    => (float)$parts[3],
            'pf'        => (float)$parts[4],
            'rf'        => (float)$parts[5],
            'sr'        => (float)$parts[6],
            'dd'        => $dd,
            'profitdd'  => $profitDD,
            'profit2dd' => $profit2DD,
            'trades'    => (float)$parts[8],
            'lots'      => (float)$parts[9],
            'config'    => $parts[10],
            'symbol'    => strtoupper(trim($parts[11])),
            'broker'    => $parts[12],
        ];
    }

    $stats = [
        'read'    => $read,
        'expired' => $expired,
        'used'    => count($rows),
    ];
    return $rows;
}

// --- Composite scores (SNR + Claude), computed over the FULL row set ---------
// These replicate the Excel formulas embedded in the analyzer's CSV export.
// Both use cross-row MIN/MAX ranges, so they must be computed after the whole
// file is loaded, not per-row in isolation.
function computeScores(&$rows) {
    if (empty($rows)) return;

    $col = function ($key) use ($rows) {
        return array_map(fn($r) => $r[$key], $rows);
    };
    $nrm = function ($v, $mn, $mx) {
        return ($mx - $mn) == 0 ? 0.0 : ($v - $mn) / ($mx - $mn);
    };

    // SNR = 0.3*norm(PF)+0.25*norm(RF)+0.25*norm(SR)+0.2*norm(Payoff)
    $pf = $col('pf'); $rf = $col('rf'); $sr = $col('sr'); $py = $col('payoff');
    $pfMn = min($pf); $pfMx = max($pf);
    $rfMn = min($rf); $rfMx = max($rf);
    $srMn = min($sr); $srMx = max($sr);
    $pyMn = min($py); $pyMx = max($py);

    // Claude composite component denominators (MAX over rows where DD<>0).
    $c1 = $c2 = $c3 = $c4 = $c5 = $c6 = $c7 = [];
    foreach ($rows as $r) {
        $dd = $r['dd'];
        $c1[] = $dd != 0 ? $r['pf'] * $r['rf'] / $dd : 0;               // 0.25
        $c2[] = $dd != 0 ? $r['profit'] / $dd : 0;                       // 0.20
        $c3[] = $r['payoff'] * $r['sr'];                                 // 0.15
        $c4[] = $r['profit2dd'];                                         // 0.15
        $c5[] = $r['profitdd'];                                          // 0.10
        $c6[] = $dd != 0 ? 1 / $dd : 0;                                  // 0.10
        $c7[] = ($dd != 0 && $r['lots'] != 0)
                    ? ($r['profit'] / $r['lots']) * ($r['rf'] / $dd) : 0; // 0.05
    }
    $m1 = max($c1) ?: 1; $m2 = max($c2) ?: 1; $m3 = max($c3) ?: 1;
    $m4 = max($c4) ?: 1; $m5 = max($c5) ?: 1; $m6 = max($c6) ?: 1; $m7 = max($c7) ?: 1;

    foreach ($rows as $i => &$r) {
        $r['snr'] = 0.3 * $nrm($r['pf'], $pfMn, $pfMx)
                  + 0.25 * $nrm($r['rf'], $rfMn, $rfMx)
                  + 0.25 * $nrm($r['sr'], $srMn, $srMx)
                  + 0.2 * $nrm($r['payoff'], $pyMn, $pyMx);

        $r['claude'] = 0.25 * ($c1[$i] / $m1)
                     + 0.20 * ($c2[$i] / $m2)
                     + 0.15 * ($c3[$i] / $m3)
                     + 0.15 * ($c4[$i] / $m4)
                     + 0.10 * ($c5[$i] / $m5)
                     + 0.10 * ($c6[$i] / $m6)
                     + 0.05 * ($c7[$i] / $m7);
    }
    unset($r);
}

// --- Metric catalogue ---------------------------------------------------------
// key => [display label, row field, direction]. direction 'max' = higher wins,
// 'min' = lower wins (DD% only).
$METRICS = [
//    'profit'    => ['Profit',      'profit',    'max'],
    'gain'      => ['Gain %',      'gain',      'max'],
    'payoff'    => ['Payoff',      'payoff',    'max'],
    'pf'        => ['PF',          'pf',        'max'],
    'rf'        => ['RF',          'rf',        'max'],
    'sr'        => ['SR',          'sr',        'max'],
    'dd'        => ['DD%',         'dd',        'min'],
//    'profitdd'  => ['Profit/DD',   'profitdd',  'max'],
    'profit2dd' => ['Profit2/DD',  'profit2dd', 'max'],
    'trades'    => ['Trades',      'trades',    'max'],
    'lots'      => ['Lots',        'lots',      'max'],
    'snr'       => ['SNR',         'snr',       'max'],
    'claude'    => ['Claude',      'claude',    'max'],
//    'first'     => ['First',       'date',      'first'],
//    'last'      => ['Last',        'date',      'last'],
];

/**
 * For a metric, return [symbol => winning row], picking best value per symbol.
 * 'max' keeps the highest, 'min' keeps the lowest.
 */
function bestPerSymbol($rows, $field, $dir) {
    $best = [];
    foreach ($rows as $r) {
        $sym = $r['symbol'];
        if ($sym === '') continue;
        $v = $r[$field];
        if (!isset($best[$sym])) { $best[$sym] = $r; continue; }
        $cur = $best[$sym][$field];
        if (($dir === 'max'   && $v > $cur) ||
            ($dir === 'min'   && $v < $cur) ||
            ($dir === 'last'  && $r['order'] > $best[$sym]['order']) ||
            ($dir === 'first' && $r['order'] < $best[$sym]['order'])) {
            $best[$sym] = $r;
        }
    }
    ksort($best);
    return $best;
}

function fmt($v) {
    return is_numeric($v) ? number_format((float)$v, 2, '.', '') : $v;
}
function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// --- Load, compute, build -----------------------------------------------------
$generatedAt = date('Y-m-d H:i:s');
$loadError = null;
$rows = [];
$parseStats = ['read' => 0, 'expired' => 0, 'used' => 0];

if (!is_readable($RESULTS_FILE)) {
    $loadError = 'Results file not found or unreadable: ' . $RESULTS_FILE;
} else {
    $content = file_get_contents($RESULTS_FILE);
    if ($content === false) {
        $loadError = 'Failed to read results file.';
    } else {
        $rows = parseResults($content, $EXPIRY_DAYS, $MIN_DAYS_LEFT, $parseStats);
        if (empty($rows)) {
            $loadError = 'No data rows parsed from results file.';
        } else {
            computeScores($rows);
        }
    }
}

// Pre-decode each config string once (keyed by string) to avoid repeat work.
$decodedCache = [];
function decodeCached($s, $fields, $enums, $version, &$cache) {
    if (!isset($cache[$s])) {
        $cache[$s] = decodeConfigMap($s, $fields, $enums, $version);
    }
    return $cache[$s];
}

// Precompute the winner set for every metric once, then count how many tabs
// each (symbol, config) pair wins. The "Also In" column reports, for a given
// row, how many OTHER metric tabs have the same symbol winning with the
// identical config string.
$winnersByMetric = [];
$symConfigTabCount = [];   // "SYMBOL\0config" => number of tabs it wins
if (!$loadError) {
    foreach ($METRICS as $mKey => [$mLabel, $mField, $mDir]) {
        $w = bestPerSymbol($rows, $mField, $mDir);
        $winnersByMetric[$mKey] = $w;
        foreach ($w as $mSym => $mRow) {
            $ck = $mSym . "\0" . $mRow['config'];
            $symConfigTabCount[$ck] = ($symConfigTabCount[$ck] ?? 0) + 1;
        }
    }
}

// Every uncommented metric doubles as a context column. The column order is the
// $METRICS order itself; per tab it's rotated so the ACTIVE metric leads and the
// rest follow in their original order, wrapping around. This keeps one consistent
// column set across tabs, the metric always first, and never a repeated header.
$COLUMN_KEYS = array_keys($METRICS);

/** Render a single metric's cell value for a given row. */
function renderMetricCell($key, $field, $r) {
    if ($key === 'gain')   return fmt($r['gain']) . '%';
    if ($key === 'trades') return (string)(int)$r['trades'];
    return fmt($r[$field]);
}

// Build tab HTML.
$tabsNav = '';
$tabsBody = '';
$first = true;

// Captured for the change report: metricKey => symbol => ['config'=>..,'value'=>..]
$currentWinners = [];

foreach ($METRICS as $key => [$label, $field, $dir]) {
    $active = $first ? ' active' : '';
    $arrow = $dir === 'min'   ? 'lowest'
           : ($dir === 'first' ? 'first seen'
           : ($dir === 'last'  ? 'last seen'
           : 'highest'));
    $tabsNav .= '<button class="tab' . $active . '" data-tab="' . h($key) . '">'
              . h($label) . '</button>';

    // Rotate the column order so this tab's metric leads, rest follow in order.
    $pos = array_search($key, $COLUMN_KEYS, true);
    $rotatedKeys = array_merge(
        array_slice($COLUMN_KEYS, $pos),
        array_slice($COLUMN_KEYS, 0, $pos)
    );

    $rowsHtml = '';
    if (!$loadError) {
        $winners = $winnersByMetric[$key];
        foreach ($winners as $sym => $r) {
            // Same symbol + identical config winning in OTHER tabs (exclude this one).
            $alsoIn = ($symConfigTabCount[$sym . "\0" . $r['config']] ?? 1) - 1;
            // Snapshot for the hourly change report.
            $currentWinners[$key][$sym] = [
                'config' => $r['config'],
                'value'  => round((float)$r[$field], 6),
            ];

            $decoded = decodeCached($r['config'], $CONFIG_FIELDS, $DECODER_ENUMS, $VERSION, $decodedCache);
            $decodedCells = '';
            foreach ($decoded as $dLabel => $dVal) {
                $decodedCells .= '<div class="cfg-row"><span class="cfg-label">' . h($dLabel)
                    . '</span><span class="cfg-val">' . h($dVal) . '</span></div>';
            }
            $metricCells = '';
            foreach ($rotatedKeys as $i => $ck) {
                [, $cField] = $METRICS[$ck];
                $cls = $i === 0 ? 'metric-val' : 'num ctx-col';
                $metricCells .= '<td class="' . $cls . '">'
                    . h(renderMetricCell($ck, $cField, $r)) . '</td>';
            }
            $rowsHtml .= '<tr>'
                . '<td class="sym">' . h($sym) . '</td>'
                . $metricCells
                . '<td class="also-in' . ($alsoIn > 0 ? ' also-hit' : '') . '"'
                    . ' title="Same symbol + identical config also wins in ' . h($alsoIn)
                    . ' other metric tab(s)">'
                    . ($alsoIn > 0 ? '<span class="pill">' . h($alsoIn) . '</span>' : h($alsoIn))
                    . '</td>'
                . '<td class="cfg-cell">'
                    . '<code class="cfg-string" title="Click to copy">' . h($r['config']) . '</code>'
                    . '<div class="cfg-decoded">' . $decodedCells . '</div>'
                . '</td>'
                . '</tr>';
        }
    }

    $body = $loadError
        ? '<div class="error">' . h($loadError) . '</div>'
        : '<div class="metric-note">Best per symbol by <strong>' . h($label)
            . '</strong> (' . $arrow . '). ' . count($winners ?? []) . ' symbols.</div>'
          . '<div class="table-wrap"><table>'
          . '<thead><tr>'
          . '<th>Symbol</th>'
          . implode('', array_map(
                fn($i, $ck) => '<th' . ($i === 0 ? '' : ' class="ctx-col"') . '>'
                    . h($METRICS[$ck][0]) . '</th>',
                array_keys($rotatedKeys), $rotatedKeys
            ))
          . '<th title="Number of other metric tabs where this same symbol wins with the identical config string">Also In</th>'
          . '<th>Config (hover to decode, click to copy)</th>'
          . '</tr></thead><tbody>' . $rowsHtml . '</tbody></table></div>';

    $tabsBody .= '<div class="tab-panel' . $active . '" id="panel-' . h($key) . '">' . $body . '</div>';
    $first = false;
}

$totalRows = count($rows);
$symbolCount = count(array_unique(array_map(fn($r) => $r['symbol'], $rows)));

$statRead    = (int)$parseStats['read'];
$statExpired = (int)$parseStats['expired'];
$statUsed    = (int)$parseStats['used'];
$statMinLeft = (int)$MIN_DAYS_LEFT;

// --- Emit page ----------------------------------------------------------------
$html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SNRC Best Config Per Symbol - {$VERSION}</title>
<link rel="apple-touch-icon" href="https://sherifawzi.github.io/Pics/SNRICON.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;1,300&family=Instrument+Sans:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --ink:      #14162e;
    --ink-deep: #0e1024;
    --paper:    #ecedf4;
    --muted:    #8d90ab;
    --gold:     #e6c15c;
  }

  * { margin:0; padding:0; box-sizing:border-box; }

  html, body { min-height:100%; }

  body {
    font-family:"Instrument Sans",-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
    background:radial-gradient(120% 140% at 50% 0%, var(--ink) 0%, var(--ink-deep) 100%);
    background-attachment:fixed;
    color:var(--paper); font-size:14px;
    display:flex; flex-direction:column; min-height:100vh;
    overflow-x:hidden;
  }

  body::after {
    content:""; position:fixed; inset:0; pointer-events:none; opacity:0.05;
    background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  }

  .wordmark-header { padding:2.5rem 3rem; }
  .wordmark {
    font-size:0.8rem; font-weight:500; letter-spacing:0.45em; text-transform:uppercase;
    color:var(--paper); user-select:none;
  }
  .wordmark span { color:var(--gold); }

  .header { text-align:center; padding:1.5rem 1.5rem 1rem; max-width:1600px; margin:0 auto; }
  .logo {
    font-family:"Cormorant Garamond",serif; font-weight:300;
    font-size:clamp(2rem,5vw,3.4rem); line-height:1.15; letter-spacing:0.01em; color:var(--paper);
  }
  .logo em { font-style:italic; color:var(--gold); padding:0 0.15em; }
  .rule { width:72px; height:1px; background:var(--gold); margin:1.75rem auto 0; }
  .meta {
    color:var(--muted); font-size:0.72rem; margin-top:1.25rem;
    letter-spacing:0.12em; text-transform:uppercase;
  }
  .meta + .meta { margin-top:0.5rem; text-transform:none; letter-spacing:0.05em; font-size:0.7rem; }
  .badge {
    display:inline-block; color:var(--gold);
    padding:2px 10px; font-size:0.68rem; font-weight:500; margin-left:6px;
    border:1px solid rgba(230,193,92,0.3); border-radius:2px; letter-spacing:0.1em;
  }
  .container {
    flex:1;
    max-width:1600px; width:100%; margin:2rem auto; padding:0 3rem;
  }
  .tabs {
    display:flex; flex-wrap:wrap; gap:0.6rem; margin-bottom:2rem;
    border-bottom:1px solid rgba(236,237,244,0.06); padding-bottom:1.25rem;
  }
  .tab {
    background:transparent; color:var(--muted);
    border:1px solid rgba(230,193,92,0.2);
    padding:0.6rem 1.3rem; border-radius:2px;
    font-family:"Instrument Sans",sans-serif; font-size:0.68rem; font-weight:500;
    letter-spacing:0.18em; text-transform:uppercase; cursor:pointer;
    transition:border-color .4s ease, color .4s ease, background .4s ease;
  }
  .tab:hover { border-color:var(--gold); color:var(--gold); background:rgba(230,193,92,0.04); }
  .tab.active {
    background:rgba(230,193,92,0.06); color:var(--gold); border-color:var(--gold);
  }
  .tab-panel { display:none; }
  .tab-panel.active { display:block; }
  .metric-note { color:var(--muted); font-size:0.85rem; margin-bottom:1.5rem; letter-spacing:0.02em; }
  .metric-note strong { color:var(--gold); font-weight:600; }
  .table-wrap {
    max-height:70vh; overflow:auto;
    border:1px solid rgba(236,237,244,0.08); border-radius:2px;
  }
  table { width:100%; border-collapse:collapse; }
  thead th {
    position:sticky; top:0; z-index:5;
    background:var(--ink-deep); color:var(--gold);
    padding:1rem 1.1rem; font-family:"Instrument Sans",sans-serif;
    font-size:0.62rem; font-weight:500; text-transform:uppercase;
    letter-spacing:0.18em; text-align:left; white-space:nowrap;
    border-bottom:1px solid rgba(230,193,92,0.3);
  }
  tbody td {
    padding:0.8rem 1.1rem; font-size:0.8rem;
    border-bottom:1px solid rgba(236,237,244,0.05);
    font-family:'Courier New',monospace; color:var(--gold); vertical-align:top;
  }
  tbody tr:nth-child(even) { background:rgba(236,237,244,0.02); }
  tbody tr:hover { background:rgba(230,193,92,0.05); }
  td.sym { font-weight:700; color:var(--paper); white-space:nowrap; }
  td.metric-val { color:var(--paper); font-weight:700; }
  td.num { color:var(--muted); white-space:nowrap; }
  td.also-in { color:var(--muted); font-weight:700; text-align:center; white-space:nowrap; }
  td.also-in.also-hit { color:var(--gold); }
  td.also-in.also-hit .pill {
    display:inline-block; min-width:22px; padding:2px 8px;
    background:transparent; border:1px solid var(--gold); color:var(--gold);
    border-radius:10px; font-size:0.72rem;
  }
  td.cfg-cell { position:relative; min-width:340px; }
  .cfg-string {
    display:block; font-size:0.68rem; color:var(--muted); word-break:break-all; cursor:pointer;
    max-width:520px;
  }
  .cfg-string:hover { color:var(--gold); }
  .cfg-decoded {
    display:none; position:absolute; z-index:50; top:100%; left:0; margin-top:4px;
    background:rgba(14,16,36,0.98); border:1px solid rgba(230,193,92,0.4); border-radius:2px;
    padding:6px; min-width:280px; max-height:360px; overflow:auto;
    box-shadow:0 8px 32px rgba(0,0,0,.6); column-count:1;
    backdrop-filter:blur(12px);
  }
  td.cfg-cell:hover .cfg-decoded { display:block; }
  .cfg-row { display:flex; justify-content:space-between; gap:14px; padding:3px 8px;
    border-bottom:1px solid rgba(236,237,244,0.05); }
  .cfg-label { color:var(--muted); font-size:0.68rem; }
  .cfg-val { color:var(--gold); font-size:0.68rem; font-weight:600; white-space:nowrap; }
  .error {
    background:rgba(230,193,92,0.04); border-left:1px solid var(--gold); color:var(--gold);
    padding:1rem 1.2rem; border-radius:2px;
  }
  .copied-toast {
    position:fixed; bottom:24px; left:50%; transform:translateX(-50%);
    background:var(--ink-deep); color:var(--gold); border:1px solid var(--gold);
    padding:10px 20px; border-radius:2px;
    font-weight:500; font-size:0.75rem; letter-spacing:0.1em; text-transform:uppercase;
    opacity:0; transition:opacity .2s; pointer-events:none; z-index:200;
  }
  .copied-toast.show { opacity:1; }

  footer {
    padding:2.5rem 3rem;
    display:flex; justify-content:space-between;
    font-size:0.68rem; letter-spacing:0.18em; text-transform:uppercase; color:var(--muted);
  }

  /* Mobile: show only Symbol, Metric, Also In, Config */
  @media (max-width:768px) {
    body { font-size:13px; }
    .header { padding:2rem 1rem 0.5rem; }
    .container { padding:0 1.25rem; margin:1.25rem auto; }
    .tabs { gap:0.4rem; padding-bottom:0.75rem; margin-bottom:1.25rem; }
    .tab { padding:0.5rem 0.9rem; font-size:0.62rem; }
    thead th.ctx-col, tbody td.ctx-col { display:none; }
    thead th, tbody td { padding:0.6rem 0.6rem; }
    td.cfg-cell { min-width:0; }
    .cfg-string { max-width:none; }
    .cfg-decoded { position:static; margin-top:6px; min-width:0; max-height:none; box-shadow:none; }
    td.cfg-cell:hover .cfg-decoded { display:none; }
    td.cfg-cell.show-decoded .cfg-decoded { display:block; }
    footer { flex-direction:column; gap:0.5rem; align-items:center; text-align:center; padding:1.75rem 1.5rem; }
  }
</style>
</head>
<body>
<header class="wordmark-header">
  <div class="wordmark">SNRoboti<span>X</span></div>
</header>
<div class="header">
  <div class="logo">Best Config <em>Per Symbol</em></div>
  <div class="rule" aria-hidden="true"></div>
  <div class="meta">
    Generated {$generatedAt}<span class="badge">{$VERSION}</span>
    <span class="badge">{$totalRows} rows</span>
    <span class="badge">{$symbolCount} symbols</span>
  </div>
  <div class="meta">
    {$statRead} results read /
    {$statExpired} expired / under {$statMinLeft}d left (not used) /
    {$statUsed} used
  </div>
</div>
<div class="container">
  <div class="tabs">{$tabsNav}</div>
  {$tabsBody}
</div>
<footer>
  <div>SNR Consulting DWC LLC</div>
  <div>Est. MMXXIII</div>
</footer>
<div class="copied-toast" id="toast">Config string copied</div>
<script>
  // Tab switching.
  document.querySelectorAll('.tab').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var key = btn.getAttribute('data-tab');
      document.querySelectorAll('.tab').forEach(function (b) { b.classList.remove('active'); });
      document.querySelectorAll('.tab-panel').forEach(function (p) { p.classList.remove('active'); });
      btn.classList.add('active');
      document.getElementById('panel-' + key).classList.add('active');
    });
  });

  // Click a config string to copy it.
  var toast = document.getElementById('toast');
  document.querySelectorAll('.cfg-string').forEach(function (el) {
    el.addEventListener('click', function () {
      var text = el.textContent;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function () {
          toast.classList.add('show');
          setTimeout(function () { toast.classList.remove('show'); }, 1400);
        });
      }
    });
  });

  // Touch devices have no hover, so tapping anywhere in a config cell EXCEPT the
  // string itself toggles the decoded parameter panel inline. Desktop keeps the
  // hover behaviour untouched.
  document.querySelectorAll('.cfg-cell').forEach(function (cell) {
    cell.addEventListener('click', function (e) {
      if (e.target.closest('.cfg-string')) return; // string tap = copy, handled above
      cell.classList.toggle('show-decoded');
    });
  });

  // Failsafe client-side refresh: reload at the next top-of-hour in case cron
  // regenerated the file while this tab stayed open. The authoritative refresh
  // is the cron job; this just re-fetches the freshly written page.
  (function () {
    var now = new Date();
    var msToNextHour = (60 - now.getMinutes()) * 60000 - now.getSeconds() * 1000
                       - now.getMilliseconds() + 2000; // +2s cron grace
    setTimeout(function () { location.reload(); }, msToNextHour);
  })();
</script>
</body>
</html>
HTML;

// Prepend the SSO guard so the written page is gated, then write it.
$written = file_put_contents($OUTPUT_FILE, $SSO_GUARD_LINE . $html);
if ($written === false) {
    fwrite(STDERR, "[" . date('c') . "] Failed to write {$OUTPUT_FILE}\n");
    exit(1);
}
echo "[" . date('c') . "] Wrote {$OUTPUT_FILE} ({$written} bytes, {$totalRows} rows, {$symbolCount} symbols)\n";

// --- Hourly change report -----------------------------------------------------
// Diff this run's winners against the previous run's saved state. Three kinds
// of change are reported: a new config took the crown, a symbol appeared for
// the first time, or a symbol disappeared from the data entirely.

if ($loadError) {
    // Nothing parsed. Don't overwrite good state with an empty snapshot,
    // otherwise the next successful run reports every symbol as "new".
    fwrite(STDERR, "[" . date('c') . "] Skipping change report: {$loadError}\n");
    exit(1);
}

$previousWinners = [];
$isFirstRun = true;
if (is_readable($STATE_FILE)) {
    $decodedState = json_decode(file_get_contents($STATE_FILE), true);
    if (is_array($decodedState)) {
        $previousWinners = $decodedState;
        $isFirstRun = false;
    }
}

/**
 * Compare old vs new winners.
 * Returns a list of change records, each with metric, symbol, kind and values.
 */
function diffWinners($prev, $curr, $metrics) {
    $changes = [];
    foreach ($curr as $metricKey => $symbols) {
        $label = $metrics[$metricKey][0] ?? $metricKey;
        foreach ($symbols as $sym => $now) {
            $was = $prev[$metricKey][$sym] ?? null;

            if ($was === null) {
                $changes[] = [
                    'metric' => $label, 'symbol' => $sym, 'kind' => 'new',
                    'oldConfig' => '', 'newConfig' => $now['config'],
                    'oldValue' => null, 'newValue' => $now['value'],
                ];
                continue;
            }

            // The crown only "changed" if a DIFFERENT config now wins.
            if (($was['config'] ?? '') !== $now['config']) {
                $changes[] = [
                    'metric' => $label, 'symbol' => $sym, 'kind' => 'improved',
                    'oldConfig' => $was['config'] ?? '', 'newConfig' => $now['config'],
                    'oldValue' => $was['value'] ?? null, 'newValue' => $now['value'],
                ];
            }
        }
    }

    // Symbols that vanished from the results file since last run.
    foreach ($prev as $metricKey => $symbols) {
        $label = $metrics[$metricKey][0] ?? $metricKey;
        foreach ($symbols as $sym => $was) {
            if (!isset($curr[$metricKey][$sym])) {
                $changes[] = [
                    'metric' => $label, 'symbol' => $sym, 'kind' => 'removed',
                    'oldConfig' => $was['config'] ?? '', 'newConfig' => '',
                    'oldValue' => $was['value'] ?? null, 'newValue' => null,
                ];
            }
        }
    }
    return $changes;
}

$changes = $isFirstRun ? [] : diffWinners($previousWinners, $currentWinners, $METRICS);

// Persist the new snapshot regardless, so the next run has a baseline.
$stateOk = file_put_contents(
    $STATE_FILE,
    json_encode($currentWinners, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES)
);
if ($stateOk === false) {
    fwrite(STDERR, "[" . date('c') . "] WARNING: could not write state file {$STATE_FILE}\n");
}

if ($isFirstRun) {
    echo "[" . date('c') . "] First run: baseline saved, no report sent.\n";
    exit(0);
}

if (empty($changes) && !$ALWAYS_SEND) {
    echo "[" . date('c') . "] No winner changes this hour. No email sent.\n";
    exit(0);
}

// --- Build and send the report ------------------------------------------------
function fmtVal($v) {
    return $v === null ? 'n/a' : number_format((float)$v, 2, '.', '');
}
function tg($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$improved = array_filter($changes, fn($c) => $c['kind'] === 'improved');
$added    = array_filter($changes, fn($c) => $c['kind'] === 'new');
$removed  = array_filter($changes, fn($c) => $c['kind'] === 'removed');

// Telegram HTML parse mode. Only b/i/u/s/a/code/pre are allowed tags, and every
// other < & > must be escaped or the API rejects the whole message.
$lines = [];
$lines[] = '<b>SNRC best-config change report</b>';
$lines[] = tg($generatedAt) . '  -  <code>' . tg(basename($RESULTS_FILE)) . '</code>';
$lines[] = tg("{$totalRows} rows / {$symbolCount} symbols");
$lines[] = '';
$lines[] = '<i>Note: only configs with at least ' . (int)$MIN_DAYS_LEFT
         . ' days left before their ' . (int)$EXPIRY_DAYS
         . '-day expiry are eligible. When an aging top config ages out, the '
         . 'crown can pass to a fresher string with a LOWER value, so a "best" '
         . 'metric may step down. That is expected, not a regression.</i>';
$lines[] = '';

if (!empty($improved)) {
    // A single strong config usually wins several metrics at once, so group by
    // symbol + config pair and print the strings once with the metrics beneath.
    $grouped = [];
    foreach ($improved as $c) {
        $gk = $c['symbol'] . "\0" . $c['oldConfig'] . "\0" . $c['newConfig'];
        $grouped[$gk][] = $c;
    }

    $lines[] = '<b>NEW BEST CONFIG</b> (' . count($improved)
             . ' metric(s), ' . count($grouped) . ' change(s))';
    $lines[] = '';

    foreach ($grouped as $group) {
        $firstC = $group[0];
        $lines[] = '<b>' . tg($firstC['symbol']) . '</b> - '
                 . count($group) . ' metric(s) improved';

        $metricLines = [];
        foreach ($group as $c) {
            $delta = '';
            if ($c['oldValue'] !== null && $c['newValue'] !== null) {
                $d = $c['newValue'] - $c['oldValue'];
                $delta = ' (' . ($d >= 0 ? '+' : '') . number_format($d, 2, '.', '') . ')';
            }
            $metricLines[] = sprintf('%-11s %s -> %s%s',
                $c['metric'], fmtVal($c['oldValue']), fmtVal($c['newValue']), $delta);
        }
        $lines[] = '<pre>' . tg(implode("\n", $metricLines)) . '</pre>';
        $lines[] = 'old: <code>' . tg($firstC['oldConfig']) . '</code>';
        $lines[] = 'new: <code>' . tg($firstC['newConfig']) . '</code>';
        $lines[] = '';
    }
}

if (!empty($added)) {
    $lines[] = '<b>NEW ENTRIES</b> (' . count($added) . ')';
    foreach ($added as $c) {
        $lines[] = '<b>' . tg($c['symbol']) . '</b> ' . tg($c['metric'])
                 . '  ' . tg(fmtVal($c['newValue']));
        $lines[] = '<code>' . tg($c['newConfig']) . '</code>';
    }
    $lines[] = '';
}

if (!empty($removed)) {
    $lines[] = '<b>NO LONGER PRESENT</b> (' . count($removed) . ')';
    $removedLines = [];
    foreach ($removed as $c) {
        $removedLines[] = sprintf('%-10s %-11s was %s',
            $c['symbol'], $c['metric'], fmtVal($c['oldValue']));
    }
    $lines[] = '<pre>' . tg(implode("\n", $removedLines)) . '</pre>';
    $lines[] = '';
}

if (empty($changes)) {
    $lines[] = '<i>No changes this run (forced by $ALWAYS_SEND).</i>';
}

$body = implode("\n", $lines);

$summaryBits = [];
if ($improved) $summaryBits[] = count($improved) . ' improved';
if ($added)    $summaryBits[] = count($added) . ' new';
if ($removed)  $summaryBits[] = count($removed) . ' removed';
$summary = $summaryBits ? implode(', ', $summaryBits) : 'no changes';

echo "[" . date('c') . "] Changes detected: {$summary}\n";

/**
 * Split a message into <=4096-char chunks on line boundaries. Telegram rejects
 * anything longer, and a big sweep across many symbols can easily exceed it.
 * Chunks are split between top-level lines so tags never straddle a boundary.
 */
function tgChunks($text, $limit = 3900) {
    $out = [];
    $buf = '';
    foreach (explode("\n", $text) as $line) {
        // A single oversized line (a very long config string) gets hard-split.
        if (strlen($line) > $limit) {
            if ($buf !== '') { $out[] = $buf; $buf = ''; }
            foreach (str_split($line, $limit) as $piece) $out[] = $piece;
            continue;
        }
        if (strlen($buf) + strlen($line) + 1 > $limit) {
            $out[] = $buf;
            $buf = $line;
        } else {
            $buf = ($buf === '') ? $line : $buf . "\n" . $line;
        }
    }
    if ($buf !== '') $out[] = $buf;
    return $out;
}

/** POST one message to the Telegram Bot API. Returns [ok, detail]. */
function tgSend($token, $chatId, $text) {
    $url = "https://api.telegram.org/bot{$token}/sendMessage";
    $payload = http_build_query([
        'chat_id'                  => $chatId,
        'text'                     => $text,
        'parse_mode'               => 'HTML',
        'disable_web_page_preview' => 'true',
    ]);

    if (function_exists('curl_init')) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 20,
        ]);
        $resp = curl_exec($ch);
        $err  = curl_error($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($resp === false) return [false, 'curl error: ' . $err];
        return [$code === 200, 'HTTP ' . $code . ' ' . $resp];
    }

    // Fallback when ext-curl isn't installed.
    $ctx = stream_context_create(['http' => [
        'method'        => 'POST',
        'header'        => "Content-Type: application/x-www-form-urlencoded\r\n",
        'content'       => $payload,
        'timeout'       => 20,
        'ignore_errors' => true,
    ]]);
    $resp = @file_get_contents($url, false, $ctx);
    if ($resp === false) return [false, 'file_get_contents failed (allow_url_fopen off?)'];
    $ok = strpos($resp, '"ok":true') !== false;
    return [$ok, $resp];
}

/** Plain-text version of the report for logs: strip tags AND decode entities. */
function tgPlain($html) {
    return html_entity_decode(strip_tags($html), ENT_QUOTES, 'UTF-8');
}

if ($TELEGRAM_TOKEN === '' || $TELEGRAM_CHAT_ID === '') {
    // Not configured: print the report so cron logs still capture it.
    echo tgPlain($body) . "\n";
    echo "[" . date('c') . "] Telegram not configured; report printed to stdout only.\n";
    exit(0);
}

$chunks = tgChunks($body);
$total = count($chunks);
$failed = 0;

foreach ($chunks as $i => $chunk) {
    $suffix = $total > 1 ? "\n<i>(" . ($i + 1) . "/{$total})</i>" : '';
    [$ok, $detail] = tgSend($TELEGRAM_TOKEN, $TELEGRAM_CHAT_ID, $chunk . $suffix);
    if (!$ok) {
        $failed++;
        fwrite(STDERR, "[" . date('c') . "] Telegram send failed (chunk "
            . ($i + 1) . "/{$total}): {$detail}\n");
    }
    if ($total > 1) usleep(400000);  // stay under the ~30 msg/sec API limit
}

if ($failed === 0) {
    echo "[" . date('c') . "] Report sent to Telegram ({$total} message(s)).\n";
} else {
    fwrite(STDERR, "[" . date('c') . "] {$failed}/{$total} Telegram message(s) failed. Report:\n"
        . tgPlain($body) . "\n");
    exit(1);
}

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$teamsPath = Join-Path $root "data\teams.json"
$playersPath = Join-Path $root "data\players.json"
$rng = [System.Random]::new(20260513)

function Roll-Stat {
    $u = $rng.NextDouble()
    if ($u -lt 0.50) { return $rng.Next(1, 4) }
    if ($u -lt 0.80) { return $rng.Next(4, 7) }
    if ($u -lt 0.95) { return $rng.Next(7, 10) }
    return 10
}

$statKeys = @(
    "speed","strength","stamina","awareness",
    "acceleration","catching","carrying","agility","toughness","tackling",
    "throw_power","throw_accuracy","blocking","route_running",
    "pass_rush","coverage","block_shedding",
    "kick_power","kick_accuracy"
)

$teams = Get-Content $teamsPath -Raw | ConvertFrom-Json
$players = [System.Collections.ArrayList]@()
$nid = 1
$usedNames = @{}

$first = @("James","Michael","Robert","David","William","Joseph","Thomas","Charles","Daniel","Matthew","Anthony","Mark","Donald","Steven","Paul","Andrew","Joshua","Kenneth","Kevin","Brian","George","Timothy","Ronald","Jason","Edward","Jeffrey","Ryan","Jacob","Gary","Nicholas","Eric","Jonathan","Stephen","Larry","Justin","Scott","Brandon","Benjamin","Samuel","Gregory","Alexander","Patrick","Frank","Raymond","Jack","Dennis","Jerry","Tyler","Aaron","Jose","Adam","Nathan","Henry","Douglas","Zachary","Peter","Kyle","Noah","Ethan","Jeremy","Walter","Christian","Keith","Roger","Terry","Austin","Sean","Gerald","Carl","Harold","Dylan","Arthur","Lawrence","Jordan","Wayne","Alan","Juan","Willie","Elijah","Randy","Roy","Vincent","Ralph","Eugene","Russell","Bobby","Mason","Philip","Louis","Mary","Patricia","Jennifer","Linda","Elizabeth","Barbara","Susan","Jessica","Sarah","Karen","Lisa","Nancy","Betty","Margaret","Sandra","Ashley","Kimberly","Emily","Donna","Michelle","Carol","Amanda","Melissa","Deborah","Stephanie","Rebecca","Laura","Sharon","Cynthia","Kathleen","Amy","Shirley","Angela","Helen","Anna","Brenda","Pamela","Nicole","Samantha","Katherine","Christine","Debra","Rachel","Carolyn","Janet","Virginia","Maria","Heather","Diane","Julie","Joyce","Victoria","Kelly","Christina","Lauren","Joan","Evelyn","Olivia","Judith","Megan","Cheryl","Martha","Andrea","Frances","Hannah","Jacqueline","Ann","Gloria","Jean","Kathryn","Alice","Teresa","Sara","Janice","Doris","Madison","Julia","Grace","Judy","Abigail","Marie","Denise","Beverly","Amber","Theresa","Marilyn","Danielle","Diana","Brittany","Natalie","Sophia","Isabella","Charlotte","Amelia","Mia","Harper","Ella","Aria","Layla")

$last = @("Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez","Wilson","Anderson","Taylor","Thomas","Moore","Jackson","Martin","Lee","Thompson","White","Harris","Clark","Lewis","Robinson","Walker","Young","Allen","King","Wright","Scott","Green","Adams","Baker","Nelson","Hall","Campbell","Mitchell","Carter","Roberts","Phillips","Evans","Turner","Parker","Collins","Edwards","Stewart","Morris","Murphy","Cook","Rogers","Morgan","Bell","Murphy","Rivera","Cooper","Richardson","Cox","Howard","Ward","Peterson","Gray","Ramirez","James","Watson","Brooks","Kelly","Sanders","Price","Bennett","Wood","Barnes","Ross","Henderson","Coleman","Jenkins","Perry","Powell","Long","Patterson","Hughes","Flores","Washington","Butler","Simmons","Foster","Gonzales","Bryant","Alexander","Russell","Griffin","Diaz","Hayes")

$colleges = @("Ohio State","Alabama","Georgia","Michigan","Texas","USC","Notre Dame","LSU","Florida","Penn State","Oregon","Clemson","Wisconsin","Nebraska","Oklahoma","Tennessee","Auburn","Stanford","UCLA","Iowa","North Carolina","Virginia Tech","Texas A&M","Washington","Utah","Baylor","TCU","Pittsburgh","Syracuse","Louisville","Cincinnati","UCF","Boise State","BYU","Colorado","Arizona","Ole Miss","South Carolina","Kentucky","Illinois","Minnesota","Purdue","Indiana","Maryland","Duke","Wake Forest","NC State","Virginia","Michigan State","Iowa State","Texas Tech","Houston","SMU","Memphis","Navy","Marshall","James Madison")

$cities = @(
    @{c="Houston";s="TX";co="USA"},@{c="Dallas";s="TX";co="USA"},@{c="Miami";s="FL";co="USA"},@{c="Atlanta";s="GA";co="USA"},
    @{c="Phoenix";s="AZ";co="USA"},@{c="Chicago";s="IL";co="USA"},@{c="Seattle";s="WA";co="USA"},@{c="Denver";s="CO";co="USA"},
    @{c="Boston";s="MA";co="USA"},@{c="Toronto";s="ON";co="Canada"},@{c="London";s="England";co="UK"},@{c="Sydney";s="NSW";co="Australia"}
)

foreach ($team in $teams) {
    $tid = $team.id
    $jerseys = 1..99 | Sort-Object { [guid]::NewGuid() }
    $teamPlayers = @()
    for ($i = 0; $i -lt 17; $i++) {
        do {
            $fn = $first[$rng.Next(0, $first.Length)]
            $ln = $last[$rng.Next(0, $last.Length)]
            $k = "$fn|$ln"
        } while ($usedNames.ContainsKey($k))
        $usedNames[$k] = $true

        $cid = "{0:D4}" -f $nid
        $nid++
        $loc = $cities[$rng.Next(0, $cities.Length)]
        $ft = $rng.Next(5,7)
        $inch = if ($ft -eq 5) { $rng.Next(8,12) } else { $rng.Next(0,8) }
        $ht = "$ft-$inch"
        $p = [ordered]@{
            id = $cid
            first_name = $fn
            last_name = $ln
            age = $rng.Next(21, 35)
            college = $colleges[$rng.Next(0, $colleges.Length)]
            hometown = "$($loc.c), $($loc.s), $($loc.co)"
            team = $tid
            jersey_number = $jerseys[$i]
            height = $ht
            weight = $rng.Next(185, 326)
        }
        foreach ($sk in $statKeys) { $p[$sk] = Roll-Stat }
        $teamPlayers += [pscustomobject]$p
    }

    function ScoreKicker($pl) { return $pl.kick_accuracy * 2 + $pl.kick_power }
    function ScorePunter($pl) { return $pl.kick_power * 2 + $pl.kick_accuracy }
    function ScoreReturner($pl) { return $pl.speed + $pl.agility + $pl.catching }
    function OffScore($pl) {
        return $pl.throw_power + $pl.throw_accuracy + $pl.route_running + $pl.catching + $pl.carrying + $pl.blocking + $pl.speed
    }
    function DefScore($pl) {
        return $pl.tackling + $pl.coverage + $pl.pass_rush + $pl.block_shedding + $pl.strength
    }

    $kicker = $teamPlayers | Sort-Object { ScoreKicker $_ } -Descending | Select-Object -First 1
    $rest = $teamPlayers | Where-Object { $_.id -ne $kicker.id }
    $punter = $rest | Sort-Object { ScorePunter $_ } -Descending | Select-Object -First 1
    $rest2 = $rest | Where-Object { $_.id -ne $punter.id }
    $returner = $rest2 | Sort-Object { ScoreReturner $_ } -Descending | Select-Object -First 1
    $fieldPool = $teamPlayers | Where-Object { $_.id -notin @($kicker.id, $punter.id, $returner.id) }

    $off7 = $fieldPool | Sort-Object { OffScore $_ } -Descending | Select-Object -First 7
    $offIds = @($off7 | ForEach-Object { $_.id })
    $defPool = $fieldPool | Where-Object { $_.id -notin $offIds }
    $def7 = $defPool | Sort-Object { DefScore $_ } -Descending | Select-Object -First 7

    $ordered = @($off7) + @($def7) + @($kicker, $punter, $returner)
    $ids = @($ordered | ForEach-Object { $_.id })
    $team | Add-Member -NotePropertyName roster_player_ids -NotePropertyValue $ids -Force
    [void]$players.AddRange($teamPlayers)
}

$players | ConvertTo-Json -Depth 6 | Set-Content $playersPath -Encoding utf8
$teams | ConvertTo-Json -Depth 8 | Set-Content $teamsPath -Encoding utf8
Write-Host "Wrote $($players.Count) players and $($teams.Count) teams."

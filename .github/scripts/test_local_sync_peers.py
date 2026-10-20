"""Exercise real encrypted HTTP sync with three independent Hive processes."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--output', default='build/local-sync-peer-results')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
output = (repo / args.output).resolve()
output.mkdir(parents=True, exist_ok=True)
control = Path(tempfile.mkdtemp(prefix='musify-sync-peers-'))
flutter = shutil.which('flutter')
if not flutter:
    raise SystemExit('Flutter must be on PATH')
workers, logs, sequences, cases = {}, {}, {}, []


def read(path, predicate=lambda _: True, timeout=180, allow_exited=False):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if path.exists():
            try:
                value = json.loads(path.read_text())
                if predicate(value):
                    return value
            except (json.JSONDecodeError, PermissionError):
                pass
        if not allow_exited:
            for role, process in workers.items():
                if process.poll() is not None:
                    raise RuntimeError(f'Peer {role} exited {process.returncode}; see {output}')
        time.sleep(.025)
    raise TimeoutError(str(path))


def start(role):
    sequences[role] = 0
    for suffix in ['ready.json', 'command.json', 'reply.json']:
        (control / f'{role}.{suffix}').unlink(missing_ok=True)
    log = (output / f'{role}-{len(logs)}.log').open('w', encoding='utf-8')
    logs[f'{role}-{len(logs)}'] = log
    workers[role] = subprocess.Popen(
        [flutter, 'test', '--no-pub', '--reporter', 'expanded', 'test/local_sync/support/peer_worker_test.dart'],
        cwd=repo, env={**os.environ, 'MUSIFY_SYNC_TEST_ROLE': role, 'MUSIFY_SYNC_TEST_ROOT': str(control)},
        stdout=log, stderr=subprocess.STDOUT,
    )
    return read(control / f'{role}.ready.json')


def send(role, op, **body):
    sequences[role] += 1
    sequence = sequences[role]
    target = control / f'{role}.command.json'
    temporary = target.with_suffix('.tmp')
    temporary.write_text(json.dumps({'op': op, 'sequence': sequence, **body}))
    for _ in range(40):
        try:
            temporary.replace(target)
            return sequence
        except PermissionError:
            time.sleep(.025)
    raise RuntimeError('Could not deliver peer command')


def receive(role, sequence):
    result = read(control / f'{role}.reply.json', lambda value: value['sequence'] == sequence)
    assert result['workerError'] is None, result['workerError']
    return result


def command(role, op, **body):
    return receive(role, send(role, op, **body))


def song(identity, title=None):
    return {'ytid': identity, 'title': title or identity, 'artist': 'Fixture'}


def playlist(identity, tracks):
    return {'ytid': identity, 'title': 'Mix', 'source': 'user-created', 'list': [song(track) for track in tracks]}


def month(minutes):
    return {'totalSeconds': minutes * 60, 'songs': {'a': {**song('a'), 'seconds': minutes * 60, 'playCount': 1}}}


def recap(minutes, history=None):
    date = time.localtime()
    return {'schemaVersion': 2, 'year': date.tm_year, 'currentMonthKey': f'{date.tm_year}-{date.tm_mon:02}', 'currentMonth': month(minutes), 'history': history or {}}


def reset(a=None, b=None, c=None):
    for role, data in [('a', a), ('b', b), ('c', c)]:
        command(role, 'reset', data=data or {})


def sync(role, target, expect_success=True, **options):
    result = command(role, 'sync', target=target, **options)
    if expect_success:
        assert result['status'] == 'success', result
    return result


def snapshot(role):
    return command(role, 'snapshot')


def identities(data, key='likedSongs'):
    return {item['ytid'] for item in data.get(key, [])}


def record(name, **detail):
    cases.append({'case': name, **detail})
    (output / 'results.json').write_text(json.dumps({'cases': cases}, indent=2))
    print(f'PASS {name}', flush=True)


try:
    for role in ['a', 'b', 'c']:
        start(role)
    reset({'likedSongs': [song('a')]}, {'likedSongs': [song('b')]}, {'likedSongs': [song('c')]})
    sync('a', 'b')
    sync('b', 'c')
    sync('c', 'a')
    command('a', 'automatic')
    values = [snapshot(role) for role in ['a', 'b', 'c']]
    assert all(identities(value['data']) == {'a', 'b', 'c'} for value in values)
    assert all(len(value['paired']) == 2 for value in values)
    record('three peers pair by PIN without approval and automatic fanout converges')

    command('a', 'edit', data={'likedSongs': [song('b'), song('c')]})
    command('a', 'automatic')
    assert all(identities(snapshot(role)['data']) == {'b', 'c'} for role in ['a', 'b', 'c'])
    record('deletion propagates to all three peers without resurrection')

    reset({'customPlaylists': [playlist('pA', ['a'])], 'pinnedPlaylistIds': ['pA']}, {'customPlaylists': [playlist('pB', ['b'])], 'pinnedPlaylistIds': ['pB']})
    sync('a', 'b')
    a, b = snapshot('a'), snapshot('b')
    assert identities(a['data'], 'customPlaylists') == identities(b['data'], 'customPlaylists') == {'pA', 'pB'}
    assert set(a['data']['pinnedPlaylistIds']) == set(b['data']['pinnedPlaylistIds']) == {'pA', 'pB'}
    record('same-name playlists retain valid identities and pins')

    cover = 'data:image/png;base64,' + 'A' * 3700000
    reset({'customPlaylists': [{**playlist('large-cover', ['a']), 'image': cover}]})
    sync('a', 'b')
    sync('b', 'c')
    sync('c', 'a')
    assert all(snapshot(role)['data']['customPlaylists'][0]['image'] == cover for role in ['a', 'b', 'c'])
    record('multi-megabyte embedded cover survives three-process sync and repeats')


    reset({'wrappedListeningStats': recap(200, {'2025-01': month(20)})}, {'wrappedListeningStats': recap(300, {'2025-02': month(30)})})
    sync('a', 'b')
    sync('a', 'b')
    for role in ['a', 'b']:
        stats = snapshot(role)['data']['wrappedListeningStats']
        assert stats['currentMonth']['totalSeconds'] == 18000
        assert {'2025-01', '2025-02'} <= set(stats['history'])
    record('full recap history copies and current month stays 300, never 500')

    command('a', 'clearRecap')
    sync('a', 'b')
    for role in ['a', 'b']:
        assert snapshot(role)['data']['wrappedListeningStats']['currentMonth']['totalSeconds'] == 0
    record('explicit recap clear does not resurrect from a paired device')

    reset({'wrappedListeningStats': recap(300)}, {'wrappedListeningStats': recap(300)}, {'wrappedListeningStats': recap(300)})
    sync('a', 'b')
    sync('b', 'c')
    command('a', 'clearRecapAndListen')
    command('a', 'automatic')
    assert all(snapshot(role)['data']['wrappedListeningStats']['currentMonth']['totalSeconds'] == 60 for role in ['a', 'b', 'c'])
    record('resuming playback before syncing a clear preserves the new one-minute recap')

    reset({'likedRadioStations': ['a']}, {'likedRadioStations': ['b']})
    sync('a', 'b')
    sync('b', 'c')
    command('a', 'addRadio', station='c')
    command('a', 'automatic')
    assert all(set(snapshot(role)['data']['likedRadioStations']) == {'a', 'b', 'c'} for role in ['a', 'b', 'c'])
    record('editing radio favourites preserves imported stations across three peers')

    history = {'2026-09': month(300)}
    reset(*[{'wrappedListeningStats': recap(300, history)} for _ in range(3)])
    sync('a', 'b')
    sync('b', 'c')
    command('a', 'edit', data={'wrappedListeningStats': recap(300)})
    command('b', 'edit', data={'wrappedListeningStats': recap(300, {'2026-09': month(200)})})
    command('a', 'automatic')
    assert all('2026-09' not in snapshot(role)['data']['wrappedListeningStats']['history'] for role in ['a', 'b', 'c'])
    command('b', 'edit', data={'wrappedListeningStats': recap(300, {'2026-09': month(10)})})
    command('b', 'automatic')
    assert all(snapshot(role)['data']['wrappedListeningStats']['history']['2026-09']['totalSeconds'] == 600 for role in ['a', 'b', 'c'])
    record('concurrent history removal wins, then an intentional re-add propagates')


    reset({'likedSongs': [song('private-a')], 'wrappedListeningStats': recap(200)}, {'likedSongs': [song('private-b')], 'wrappedListeningStats': recap(300)})
    command('b', 'categories', categories=['recap'])
    sync('a', 'b')
    assert identities(snapshot('a')['data']) == {'private-a'}
    assert identities(snapshot('b')['data']) == {'private-b'}
    record('only mutually selected categories transfer')

    a_before = snapshot('a')
    failed = sync('a', 'b', expect_success=False, unreachable=True)
    assert failed['status'] == 'error'
    assert failed['paired'] == a_before['paired']
    assert failed['data'] == a_before['data']
    sync('a', 'b')
    record('unreachable peer preserves pairing and data, reconnect succeeds')

    command('b', 'off')
    failed = sync('a', 'b', expect_success=False)
    assert failed['status'] == 'error'
    assert failed['paired'] == a_before['paired']
    command('b', 'on')
    sync('a', 'b')
    record('turning peer off and on preserves trust across changed ports')

    reset({'likedSongs': [song('a')]}, {'likedSongs': [song('b')]})
    request_a = send('a', 'sync', target='b')
    request_b = send('b', 'sync', target='a')
    assert receive('a', request_a)['status'] == 'success'
    assert receive('b', request_b)['status'] == 'success'
    assert identities(snapshot('a')['data']) == identities(snapshot('b')['data']) == {'a', 'b'}
    record('simultaneous authenticated bidirectional sync completes without deadlock')

    reset({'likedSongs': [song('before')]}, {'likedSongs': [song('remote')]})
    before = snapshot('a')
    command('a', 'crashOnMerge')
    sequence = send('b', 'sync', target='a')
    workers['a'].wait(timeout=20)
    assert workers['a'].returncode != 0
    assert (control / 'a.crash').read_text() == 'written'
    # The survivor can report its failed request while the crashed peer is down.
    result = read(control / 'b.reply.json', lambda value: value['sequence'] == sequence, allow_exited=True)
    assert result['status'] == 'error'
    start('a')
    restored = snapshot('a')
    assert restored['data'] == before['data'], (restored, before)
    assert restored['paired'] == before['paired']
    assert restored['journal'] is False
    sync('b', 'a')
    assert identities(snapshot('a')['data']) == {'before', 'remote'}
    record('actual process death after durable writes recovers journal and retries safely')

    print(f'{len(cases)} independent-peer scenarios passed', flush=True)
finally:
    for role, process in workers.items():
        if process.poll() is None:
            try:
                send(role, 'stop')
                process.wait(timeout=15)
            except (OSError, subprocess.TimeoutExpired):
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
    for log in logs.values():
        log.close()
    shutil.rmtree(control, ignore_errors=True)

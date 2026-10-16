"""Plan 02 QA via current BE. Credentials arrive on stdin, never saved/logged."""
import json
import sys
import urllib.error
import urllib.request

request = json.load(sys.stdin)
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
origin = 'http://127.0.0.1:18080'
sessions = []


def call(path, method='GET', data=None, token=None, form=False):
    headers = {}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    if form:
        boundary = 'plan02qa14'
        body = ('--' + boundary + '\r\nContent-Disposition: form-data; name="avatarUrl"\r\n\r\n'
                + (data or '') + '\r\n--' + boundary + '--\r\n').encode()
        headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary
    else:
        body = json.dumps(data).encode() if data is not None else None
        headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(origin + path, data=body, headers=headers, method=method)
    try:
        with opener.open(req, timeout=20) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read())


def login(password):
    status, result = call('/api/v1/auth/login', 'POST',
                          {'username': request['username'], 'password': password})
    if status == 200 and result.get('success'):
        sessions.append(result['data'])
    return status, result


try:
    action = request['action']
    if action == 'password-verify-and-restore':
        status, result = login(request['temporaryPassword'])
        assert status == 200 and result.get('success'), 'Temporary password login failed; no restore attempted'
        token = result['data']['accessToken']
        try:
            status_old, _ = login(request['password'])
            assert status_old == 401, 'Previous password was not rejected'
            status_profile, profile = call('/api/v1/users/me', token=token)
            assert status_profile == 200 and profile.get('success')
            print('Temporary password login PASS; previous password rejected 401; profile GET PASS')
        finally:
            status_reset, result_reset = call('/api/v1/users/me/password', 'POST', {
                'oldPassword': request['temporaryPassword'], 'newPassword': request['password'],
                'confirmPassword': request['password']}, token=token)
            assert status_reset == 200 and result_reset.get('success'), 'Password restore failed'
            print('Original password restored via BE API')
        status_restored, restored = login(request['password'])
        assert status_restored == 200 and restored.get('success'), 'Restored password login failed'
        print('Original password login PASS after restore')
    else:
        status, result = login(request['password'])
        assert status == 200 and result.get('success'), 'Credential login failed'
        token = result['data']['accessToken']
        status_profile, result_profile = call('/api/v1/users/me', token=token)
        assert status_profile == 200 and result_profile.get('success')
        if action == 'baseline':
            print(json.dumps(result_profile['data'], ensure_ascii=False))
        elif action == 'avatar-restore':
            status_avatar, result_avatar = call('/api/v1/users/me/avatar', 'POST',
                request.get('avatarUrl'), token=token, form=True)
            assert status_avatar == 200 and result_avatar.get('success')
            assert result_avatar['data'].get('avatarUrl') == request.get('avatarUrl')
            print('Original avatar restored via BE API')
        elif action == 'profile-assert':
            for key, value in request['expected'].items():
                assert result_profile['data'].get(key) == value, 'Profile mismatch for ' + key
            print('Persisted profile GET matches expected fields')
        else:
            raise RuntimeError('Unsupported action')
finally:
    for session in sessions:
        call('/api/v1/auth/logout', 'POST', {'refreshToken': session['refreshToken']})

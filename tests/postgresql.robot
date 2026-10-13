*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234

*** Test Cases ***
Check if postgresql is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if postgresql can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"postgresql.domain.org","http2https": true,"lets_encrypt": true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check postgresql path is configured
    ${ocfg} =   Run task    module/${module_id}/get-configuration    {}
    Set Suite Variable     ${HOST}    ${ocfg['host']}
    Set Suite Variable     ${HTTP2HTTPS}    ${ocfg['http2https']}
    Set Suite Variable     ${LE_ENCRYPT}    ${ocfg['lets_encrypt']}
    Should Not Be Empty    ${HOST}
    Should Be True    ${HTTP2HTTPS}
    Should Be True    ${LE_ENCRYPT}

Check if posgresql works as expected
    Wait Until Keyword Succeeds    20 times    3 seconds    Ping postgresql

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=about
    Wait For Elements State    iframe >>> h2 >> text="About"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/3._About.png
    Close Browser

Check if postgresql is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Ping postgresql
    ${out}  ${err}  ${rc} =    Execute Command    curl -k -f -H 'Host: postgresql.domain.org' https://127.0.0.1/login
    ...    return_rc=True  return_stdout=True  return_stderr=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${out}    <title>pgAdmin

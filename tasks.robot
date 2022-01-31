*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs
#Suite Teardown    Teardown

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    3x
${GLOBAL_RETRY_INTERVAL}=    10.0s
${GLOBAL_DOWNLOAD_DIR}=    ${CURDIR}${/}download
${GLOBAL_RECEIPTS_DIR}=    ${OUTPUT_DIR}${/}receipts
${GLOBAL_RECEIPTS_ZIP}=    ${OUTPUT_DIR}${/}receipts.zip
#${xpath_model_name}    //table[@id='model-info']//td[text()='1']/parent::tr/td[not(text()='1')]

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Setup]    Startup
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Teardown

*** Keywords ***
Startup
    Remove Directory    ${GLOBAL_RECEIPTS_DIR}    recursive=true
    Remove File    ${GLOBAL_RECEIPTS_ZIP}
    ${url_robot_order_orders_csv}=    Collect CSV URL From User    # https://robotsparebinindustries.com/orders.csv
    Set Test Variable    \${TEST_CSV_URL}    ${url_robot_order_orders_csv}

Open the robot order website
    ${url_robot_order_website}=    Get Secret Url for robot order website
    Open Chrome Browser    ${url_robot_order_website}    maximized=true

Get Secret Url for robot order website
    ${secret}=    Get Secret    credentials    #as defined in dedata/vault.json
    Log    ${secret}[url_robot_order]
    [Return]    ${secret}[url_robot_order]

Get orders
    ${csv_path}=    Set Variable    ${GLOBAL_DOWNLOAD_DIR}${/}orders.csv
    #${url_robot_order_orders_csv}=    Collect CSV URL From User    # https://robotsparebinindustries.com/orders.csv
    Download
    ...    ${TEST_CSV_URL}
    ...    overwrite=true
    ...    target_file=${csv_path}
    ${orders}=    Read table from CSV
    ...    ${csv_path}
    ...    header=true
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${form_data}
    #Head
    Select From List By Value    id:head    ${form_data}[Head]
    #Body
    Select Radio Button    body    ${form_data}[Body]
    #Legs
    ${legs_label_for_value}=    Get Element Attribute    xpath://label[contains(text(),'Legs')]    for
    Input Text    id:${legs_label_for_value}    ${form_data}[Legs]
    #Address
    Input Text    css:#address    ${form_data}[Address]

Submit the order
    Wait Until Keyword Succeeds
...    ${GLOBAL_RETRY_AMOUNT}
...    ${GLOBAL_RETRY_INTERVAL}
...    Submit the order with assert

Submit the order with assert
    Click Button    order
    Assert order succeed

Assert order succeed
    Wait Until Element Is Visible    id:order-another
    Page Should Contain Element    id:order-another

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image
    Page Should Contain Element    id:robot-preview-image

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${output_path}=    Set Variable    ${GLOBAL_RECEIPTS_DIR}${/}${order_number}.pdf
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${output_path}
    [Return]    ${output_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${output_path}=    Set Variable    ${GLOBAL_DOWNLOAD_DIR}${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${output_path}
    [Return]    ${output_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    ${files}=    Create List    ${screenshot}:align=center
    #Open Pdf    ${pdf}
    Add Files To Pdf    files=${files}    target_document=${pdf}    append=true
    Remove File    ${screenshot}
    #Close Pdf    source_pdf=${pdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${GLOBAL_RECEIPTS_DIR}    ${GLOBAL_RECEIPTS_ZIP}

Collect CSV URL From User
    Add text input    url    label=Wpisz url do pobrania csv
    ${response}=    Run dialog    on_top=${TRUE}    height=300
    [Return]    ${response.url}

Teardown
    Close Browser
    Remove Directory    ${GLOBAL_DOWNLOAD_DIR}    recursive=true

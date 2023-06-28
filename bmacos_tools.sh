#!/usr/bin/env bash

function _bmacos_capslock_tab_help()
{
    printf "%s\n\n" 'map CAPSLOCK 0x700000039 to TAB 0x70000002B'

    printf "%s\n" 'https://developer.apple.com/library/archive/technotes/tn2450/_index.html'
    printf "%s\n" 'Note: the Capslock Modifier setting must be the default (i.e. Caps Lock) for this to affect it'
    printf "%s\n" 'Note: Must be run on every restart because setting is reset to default. (see ~/.bash_profile)'
}

function bmacos_capslock_tab()
{

    read -r -d '' KEY_MAPPING <<- EOM
    {
        "UserKeyMapping":[
            {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000002B}
        ]
    }
EOM

    hidutil property --set "${KEY_MAPPING}" &> /dev/null

}

function _bmacos_default_text_editor_help()
{
    printf "%s\n\n" 'map vscode as system default text editor'

    printf "%s\n" 'https://apple.stackexchange.com/questions/123833/replace-text-edit-as-the-default-text-editor/123834#123834'
    printf "%s\n" 'Note: Must restart machine after using. Does NOT need to be run on every restart.'

}


function bmacos_default_text_editor()
{

    defaults write com.apple.LaunchServices/com.apple.launchservices.secure \
        LSHandlers -array-add \
        '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.microsoft.VSCode;}'
}

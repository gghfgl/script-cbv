#!/bin/bash

NOW="$(date +'%B %d, %Y')"
RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

LATEST_HASH=`git log --pretty=format:'%h' -n 1`

QUESTION_FLAG="${GREEN}?"
WARNING_FLAG="${YELLOW}!"
NOTICE_FLAG="${CYAN}❯"

ADJUSTMENTS_MSG="${QUESTION_FLAG} Now you can make adjustments to ${WHITE}CHANGELOG.md${GREEN}. Then press enter to continue.${RESET}"
PUSHING_MSG="${NOTICE_FLAG} Pushing new version to the ${WHITE}origin${CYAN}..."

SCRIPT_CATEGORY="${GREEN}Please specify the script to execute:
(${WHITE}C${GREEN})hangelog
(${WHITE}B${GREEN})ump version${RESET}
"

CONTEXT_CATEGORY="${GREEN}Please specify the context:${GREEN}
(${WHITE}U${GREEN})nreleased${RESET}
"

CHANGE_CATEGORY="${GREEN}Please specify the category of your change:
(${WHITE}N${GREEN})ew feature
(${WHITE}B${GREEN})ug fix
(${WHITE}C${GREEN})hange feature
(${WHITE}R${GREEN})emove feature${RESET}
"

UNRELEASED_CONTEXT="## [Unreleased]"
CHANGELOG_COMMIT_MSG="Update CHANGELOG.md"

# Show SCRIPT list
echo -ne "$SCRIPT_CATEGORY"
read SCRIPT

# CHANGELOG script
if [[ "$SCRIPT" = [1Cc] ]]; then

    # Create CHANGELOG.md if missing
    if [ ! -f CHANGELOG.md ]; then
        echo -ne "${QUESTION_FLAG} Please type the name of the project?${RESET}
"
        read PROJECT_NAME
        touch CHANGELOG.md
        echo "# Changelog $PROJECT_NAME" >> CHANGELOG.md
    fi

    # Show  CONTEXT list
    if [ -f VERSION ]; then
        CURRENT_VERSION=`cat VERSION`
        CURRENT_VERSION="v$CURRENT_VERSION"
        CONTEXT_LIST_ADD="${GREEN}(${WHITE}V${GREEN})$CURRENT_VERSION
(${WHITE}M${GREEN})erge Unreleased into $CURRENT_VERSION${RESET}
"
    fi
    echo -ne "$CONTEXT_CATEGORY"
    echo -ne "$CONTEXT_LIST_ADD"
    read CONTEXT

    # Add and commit new MESSAGE to CONTEXT
    if [[ "$CONTEXT" = [1Uu2Vv] ]]; then
        if [[ "$CONTEXT" = [1Uu] ]]; then
            CONTEXT=$UNRELEASED_CONTEXT
        elif [[ "$CONTEXT" = [2Vv] ]]; then
            CONTEXT="## [$CURRENT_VERSION]"
        fi

        # Select CHANGE
        echo -ne "$CHANGE_CATEGORY"
        read CHANGE
        case "$CHANGE" in
            "1"|"N"|"n")PREFIX_LOG="### Added"
                ;;
            "2"|"B"|"b")PREFIX_LOG="### Fixed"
                ;;
            "3"|"C"|"c")PREFIX_LOG="### Changed"
                ;;
            "4"|"R"|"r")PREFIX_LOG="### Removed"
                ;;
            *)
                echo "Invalid option"
                ;;
        esac

        # if prefix in range
        if [ "$PREFIX_LOG" != "" ]; then
            # Ask for type MESSAGE
            echo -ne "${GREEN}Please type a well formed message [$CONTEXT | $PREFIX_LOG]:${RESET}
> "
            read MESSAGE

            # Read CHANGELOG.md
            COUNT=0
            LINE_TO_UNRELEASED=0
            LINE_TO_CONTEXT=0
            LINE_TO_PREFIX=0
            LINE_TO_NEXT_MATCH=0
            while read line
            do
                COUNT=$(( $COUNT + 1 ))

                ## Needed to keep UNRELEASED on top
                # if UNRELEASED context found keep track on line
                if [[ "$line" = "$UNRELEASED_CONTEXT"* ]]; then
                    LINE_TO_UNRELEASED=$COUNT
                # if UNRELEASED context exists find the next CONTEXT and keep track on line
                elif [ $LINE_TO_UNRELEASED != 0 ] && [ $LINE_TO_NEXT_MATCH = 0 ]; then
                    MATCH_NEXT_CONTEXT=$(echo $line | cut -c1-4)
                    if [ "$MATCH_NEXT_CONTEXT" = "## [" ]; then
                        LINE_TO_NEXT_MATCH=$COUNT
                    fi
                fi

                ## Get PREFIX_LOG line
                # if the CONTEXT was found
                if [ $LINE_TO_CONTEXT != 0 ]; then
                    MATCH_NEXT_CONTEXT=$(echo $line | cut -c1-4)
                    # and if next CONTEXT was found too break here to keep the line
                    if [ "$MATCH_NEXT_CONTEXT" = "## [" ]; then
                        break
                    fi
                    # else if PREFIX match keep track on line
                    if [ "$line" = "$PREFIX_LOG" ]; then
                        LINE_TO_PREFIX=$COUNT                        
                    fi
                fi

                ## Get CONTEXT line
                # if CONTEXT found keep track on line
                if [[ "$line" = "$CONTEXT"* ]]; then
                    LINE_TO_CONTEXT=$COUNT
                fi
            done < CHANGELOG.md

            ## Insert MESSAGE
            # if CONTEXT already exists
            if [ $LINE_TO_CONTEXT != 0 ]; then
                # and PREFIX too
                if [ $LINE_TO_PREFIX != 0 ]; then
                    gsed -i "$LINE_TO_PREFIX a - $MESSAGE" CHANGELOG.md
                # but PREFIX not
                else
                    LINE_TO_CONTEXT=$(( $LINE_TO_CONTEXT + 1 ))
                    gsed -i "$LINE_TO_CONTEXT a $PREFIX_LOG\n- $MESSAGE\n" CHANGELOG.md

                fi
            # else if CONTEXT does not exists
            else
                # if UNRELEASED does not exists
                if [ $LINE_TO_UNRELEASED = 0 ]; then
                    gsed -i "1 a\ " CHANGELOG.md
                    gsed -i "2 a $CONTEXT ($NOW)\n\n$PREFIX_LOG\n- $MESSAGE" CHANGELOG.md
                # if UNRELEASED exists find next CONTEXT and prepend
                elif [ $LINE_TO_NEXT_MATCH != 0 ]; then
                    gsed -i "$LINE_TO_NEXT_MATCH i $CONTEXT ($NOW)\n\n$PREFIX_LOG\n- $MESSAGE\n" CHANGELOG.md
                # if UNRELEASED exists but any other CONTEXT found then append EOF
                else
                    gsed -i "$COUNT a\ " CHANGELOG.md
                    COUNT=$(( $COUNT + 1 ))
                    gsed -i "$COUNT a $CONTEXT ($NOW)\n\n$PREFIX_LOG\n- $MESSAGE" CHANGELOG.md
                fi                    
            fi

            # DEBUG:
            # echo -e "message: $MESSAGE"
            # echo -e "l_unreleased: $LINE_TO_UNRELEASED"
            # echo -e "l_next_match: $LINE_TO_NEXT_MATCH"
            # echo -e "c_next_match: $MATCH_NEXT_CONTEXT"
            # echo -e "l_context : $LINE_TO_CONTEXT"
            # echo -e "l_prefix: $LINE_TO_PREFIX"
            
            ## Commit changes
            echo -e "${QUESTION_FLAG} Commit changes from CHANGELOG.md ? [${WHITE}y${GREEN}/${WHITE}n${GREEN}]${RESET}"
            read RESPONSE
            if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "y" ]; then
                echo -e "$CHANGELOG_COMMIT_MSG"
                git add CHANGELOG.md
                git commit -m "Update CHANGELOG.md."
                git push origin
                echo -e "${RESET}"
            fi
        fi

        # Merge UNRELEASED to CURRENT_VERSION
    elif [[ "$CONTEXT" = [3Mm] ]]; then
        echo -ne "${QUESTION_FLAG} Do you want to merge [Unreleased] block to [$CURRENT_VERSION] ? [${WHITE}y${GREEN}/${WHITE}n${GREEN}]${RESET}"
        read RESPONSE
        if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "y" ]; then

            # Read CHANGELOG.md
            UNRELEASED_COUNT=0
            LINE_TO_UNRELEASED=0

            PREFIX_ADDED_FOUND=false
            PREFIX_FIXED_FOUND=false
            PREFIX_CHANGED_FOUND=false
            PREFIX_REMOVED_FOUND=false

            CURRENT_VERSION_FOUND=false

            declare -a ADDED_MESSAGES
            declare -a FIXED_MESSAGES
            declare -a CHANGED_MESSAGES
            declare -a REMOVED_MESSAGES

            # retrieve UNRELEASED messages
            while read line
            do
                UNRELEASED_COUNT=$(( $UNRELEASED_COUNT + 1 ))

                # check if CURRENT_VERSION exists
                if [[ "$line" = "## [$CURRENT_VERSION]"* ]]; then
                    CURRENT_VERSION_FOUND=true
                fi

                # Get UNRELEASED context line
                if [[ "$line" = "$UNRELEASED_CONTEXT"* ]]; then
                    LINE_TO_UNRELEASED=$UNRELEASED_COUNT
                    # break when UNRELEASED block is ending
                elif [ $LINE_TO_UNRELEASED != 0 ]; then
                    if [[ "$line" = "## ["* ]]; then
                        break
                    fi

                    # fetch messages
                    if [ $PREFIX_ADDED_FOUND = true ] && [ "$line" !=  "" ] && [[ "$line" != "###"* ]]; then
                        ADDED_MESSAGES+=("$line")
                    fi
                    if [ $PREFIX_FIXED_FOUND = true ] && [ "$line" !=  "" ] && [[ "$line" != "###"* ]]; then
                        FIXED_MESSAGES+=("$line")
                    fi
                    if [ $PREFIX_CHANGED_FOUND = true ] && [ "$line" !=  "" ] && [[ "$line" != "###"* ]]; then
                        CHANGED_MESSAGES+=("$line")
                    fi
                    if [ $PREFIX_REMOVED_FOUND = true ] && [ "$line" !=  "" ] && [[ "$line" != "###"* ]]; then
                        REMOVED_MESSAGES+=("$line")
                    fi

                    # track prefixes
                    if [ "$line" = "### Added" ]; then
                        PREFIX_ADDED_FOUND=true
                        PREFIX_FIXED_FOUND=false
                        PREFIX_CHANGED_FOUND=false
                        PREFIX_REMOVED_FOUND=false
                    elif [ "$line" = "### Fixed" ]; then
                        PREFIX_ADDED_FOUND=false
                        PREFIX_FIXED_FOUND=true
                        PREFIX_CHANGED_FOUND=false
                        PREFIX_REMOVED_FOUND=false
                    elif [ "$line" = "### Changed" ]; then
                        PREFIX_ADDED_FOUND=false
                        PREFIX_FIXED_FOUND=false
                        PREFIX_CHANGED_FOUND=true
                        PREFIX_REMOVED_FOUND=false
                    elif [ "$line" = "### Removed" ]; then
                        PREFIX_ADDED_FOUND=false
                        PREFIX_FIXED_FOUND=false
                        PREFIX_CHANGED_FOUND=false
                        PREFIX_REMOVED_FOUND=true
                    fi
                fi
            done < CHANGELOG.md

            # DEBUG:
            # echo -e "ADDED[${#ADDED_MESSAGES[@]}]: ${ADDED_MESSAGES[@]}"
            # echo -e "FIXED[${#FIXED_MESSAGES[@]}]: ${FIXED_MESSAGES[@]}"
            # echo -e "CHANGED[${#CHANGED_MESSAGES[@]}]: ${CHANGED_MESSAGES[@]}"
            # echo -e "REMOVED[${#REMOVED_MESSAGES[@]}]: ${REMOVED_MESSAGES[@]}"

            # abort if CURRENT_VERSION not found
            if [ $CURRENT_VERSION_FOUND = false ]; then
                echo -e "${RED}Error${RESET} $CURRENT_VERSION not found in CHANGELOG.md\n"
                exit 0;
            fi

            CURRENT_VERSION_COUNT=0
            LINE_TO_CURRENT_VERSION=0

            LINE_TO_ADDED_PREFIX=0
            LINE_TO_FIXED_PREFIX=0
            LINE_TO_CHANGED_PREFIX=0
            LINE_TO_REMOVED_PREFIX=0

            if [ $LINE_TO_UNRELEASED = 0 ]; then
                echo -e "${RED}Error${RESET} ## [Unreleased] block not found\n"
                exit 0;
            else
                # retrieve CURRENT_VERSION positions
                while read line
                do
                    CURRENT_VERSION_COUNT=$(( $CURRENT_VERSION_COUNT + 1 ))

                    # Get CURRENT_VERSION context line
                    if [[ "$line" = "## [$CURRENT_VERSION]"* ]]; then
                        LINE_TO_CURRENT_VERSION=$CURRENT_VERSION_COUNT
                        # break when CURRENT_VERSION block is ending
                    elif [ $LINE_TO_CURRENT_VERSION != 0 ]; then
                        if [[ "$line" = "## ["* ]]; then
                            break
                        fi

                        if [ "$line" = "### Added" ] && [ $LINE_TO_ADDED_PREFIX = 0 ]; then
                            LINE_TO_ADDED_PREFIX=$CURRENT_VERSION_COUNT
                        fi
                        if [ "$line" = "### Fixed" ] && [ $LINE_TO_FIXED_PREFIX = 0 ]; then
                            LINE_TO_FIXED_PREFIX=$CURRENT_VERSION_COUNT
                        fi
                        if [ "$line" = "### Changed" ] && [ $LINE_TO_CHANGED_PREFIX = 0 ]; then
                            LINE_TO_CHANGED_PREFIX=$CURRENT_VERSION_COUNT
                        fi
                        if [ "$line" = "### Removed" ] && [ $LINE_TO_REMOVED_PREFIX = 0 ]; then
                            LINE_TO_REMOVED_PREFIX=$CURRENT_VERSION_COUNT
                        fi
                    fi
                done < CHANGELOG.md

                # DEBUG:
                # echo -e "l_to_current_v_start: $LINE_TO_CURRENT_VERSION"
                # echo -e "l_current_v_end: $CURRENT_VERSION_COUNT"
                # echo -e "l_to_added: $LINE_TO_ADDED_PREFIX"
                # echo -e "l_to_fixed: $LINE_TO_FIXED_PREFIX"
                # echo -e "l_to_changed: $LINE_TO_CHANGED_PREFIX"
                # echo -e "l_to_removed: $LINE_TO_REMOVED_PREFIX"

                # Merge UNRELEASED messages in CURRENT_VERSION
                if [[ ${#ADDED_MESSAGES[@]} > 0 ]]; then
                    KEEP_ORDER=$LINE_TO_ADDED_PREFIX
                    # if any prefix found insert prefix after the CURRENT_VERSION
                    if [ $LINE_TO_ADDED_PREFIX = 0 ]; then
                        KEEP_ORDER=$LINE_TO_CURRENT_VERSION
                        gsed -i "$KEEP_ORDER a\ " CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                        gsed -i "$KEEP_ORDER a ### Added" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    fi

                    for m in "${ADDED_MESSAGES[@]}"
                    do
                        gsed -i "$KEEP_ORDER a $m" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    done
                fi

                if [[ ${#FIXED_MESSAGES[@]} > 0 ]]; then
                    KEEP_ORDER=$LINE_TO_FIXED_PREFIX
                    # if any prefix found insert prefix after the CURRENT_VERSION
                    if [ $LINE_TO_FIXED_PREFIX = 0 ]; then
                        KEEP_ORDER=$LINE_TO_CURRENT_VERSION
                        gsed -i "$KEEP_ORDER a\ " CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                        gsed -i "$KEEP_ORDER a ### Fixed" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    fi

                    for m in "${FIXED_MESSAGES[@]}"
                    do
                        gsed -i "$KEEP_ORDER a $m" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    done
                fi

                if [[ ${#CHANGED_MESSAGES[@]} > 0 ]]; then
                    KEEP_ORDER=$LINE_TO_CHANGED_PREFIX
                    # if any prefix found insert prefix after the CURRENT_VERSION
                    if [ $LINE_TO_CHANGED_PREFIX = 0 ]; then
                        KEEP_ORDER=$LINE_TO_CURRENT_VERSION
                        gsed -i "$KEEP_ORDER a\ " CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                        gsed -i "$KEEP_ORDER a ### Changed" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    fi

                    for m in "${CHANGED_MESSAGES[@]}"
                    do
                        gsed -i "$KEEP_ORDER a $m" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    done
                fi

                if [[ ${#REMOVED_MESSAGES[@]} > 0 ]]; then
                    KEEP_ORDER=$LINE_TO_REMOVED_PREFIX
                    # if any prefix found insert prefix after the CURRENT_VERSION
                    if [ $LINE_TO_REMOVED_PREFIX = 0 ]; then
                        KEEP_ORDER=$LINE_TO_CURRENT_VERSION
                        gsed -i "$KEEP_ORDER a\ " CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                        gsed -i "$KEEP_ORDER a ### Removed" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    fi

                    for m in "${REMOVED_MESSAGES[@]}"
                    do
                        gsed -i "$KEEP_ORDER a $m" CHANGELOG.md
                        KEEP_ORDER=$(( $KEEP_ORDER + 1 ))
                    done
                fi                               
            fi

            # Delete UNRELEASED block
            UNRELEASED_END_BLOCK=$(( $LINE_TO_CURRENT_VERSION - 1 ))
            gsed -i "$LINE_TO_UNRELEASED,$UNRELEASED_END_BLOCK d" CHANGELOG.md

            ## Commit changes
            echo -e "${QUESTION_FLAG} Commit changes from CHANGELOG.md ? [${WHITE}y${GREEN}/${WHITE}n${GREEN}]${RESET}"
            read RESPONSE
            if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
            if [ "$RESPONSE" = "y" ]; then
                echo -e "$CHANGELOG_COMMIT_MSG"
                git add CHANGELOG.md
                git commit -m "Update CHANGELOG.md."
                git push origin
                echo -e "${RESET}"
            fi
        fi
    fi

# if BUMP_VERSION script
elif [[ "$SCRIPT" = [2Bb] ]]; then
    if [ -f VERSION ]; then

        while read line
        do
            # Exit if UNRELEASED context found
            if [[ "$line" = "$UNRELEASED_CONTEXT"* ]]; then
                echo -e "${RED}Error${RESET} Cannot bump version when UNRELEASED Block is in process. Please merge before bumping version\n"
                exit 0;
            fi
        done < CHANGELOG.md
                   
        BASE_STRING=`cat VERSION`
        BASE_LIST=(`echo $BASE_STRING | tr '.' ' '`)
        V_MAJOR=${BASE_LIST[0]}
        V_MINOR=${BASE_LIST[1]}
        V_PATCH=${BASE_LIST[2]}
        echo -e "${NOTICE_FLAG} Current version: ${WHITE}$BASE_STRING"
        echo -e "${NOTICE_FLAG} Latest commit hash: ${WHITE}$LATEST_HASH"
        V_MINOR=$((V_MINOR + 1))
        V_PATCH=0
        SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"
        echo -ne "${QUESTION_FLAG} Enter a version number [${WHITE}$SUGGESTED_VERSION${GREEN}]: ${RESET}"
        read INPUT_STRING
        if [ "$INPUT_STRING" = "" ]; then
            INPUT_STRING=$SUGGESTED_VERSION
        fi
        echo -e "${NOTICE_FLAG} Will set new version to be ${WHITE}$INPUT_STRING"
        echo $INPUT_STRING > VERSION

        # retrieve CURRENT_VERSION positions
        LINE_TO_CURRENT_VERSION=0
        while read line
        do
            CURRENT_VERSION_COUNT=$(( $CURRENT_VERSION_COUNT + 1 ))

            # Get CURRENT_VERSION context line
            if [[ "$line" = "## [v$BASE_STRING]"* ]]; then
                LINE_TO_CURRENT_VERSION=$CURRENT_VERSION_COUNT
            fi
        done < CHANGELOG.md

        if [ $LINE_TO_CURRENT_VERSION == 0 ]; then
            echo -e "${RED}Error${RESET} Current version not found in CHANGELOG.md\n"
            exit 0;
        else
            UPPER_LINE=$(( $LINE_TO_CURRENT_VERSION - 1 ))
            #gsed -i "2 a\ " CHANGELOG.md
            gsed -i "2 a ## [v$INPUT_STRING] ($NOW)\n" CHANGELOG.md
        fi
        
        #echo -e "$ADJUSTMENTS_MSG"
        #read
        echo -e "$PUSHING_MSG"
        git add VERSION
        git add CHANGELOG.md
        git commit -m "Bump version to ${INPUT_STRING}."
        git tag -a -m "Tag version ${INPUT_STRING}." "v$INPUT_STRING"
        git push origin --tags
    else
        echo -e "${WARNING_FLAG} Could not find a VERSION file."
        echo -ne "${QUESTION_FLAG} Do you want to create a version file and start from scratch ? [${WHITE}y${GREEN}/${WHITE}n${GREEN}]${RESET}"
        read RESPONSE
        if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
        if [ "$RESPONSE" = "y" ]; then
            echo "0.1.0" > VERSION

            # Create CHANGELOG.md if missing
            if [ ! -f CHANGELOG.md ]; then
                echo -e "${WARNING_FLAG} Could not find a CHANGELOG file."
                echo -ne "${QUESTION_FLAG} Do you want to create a CHANGELOG file ? [${WHITE}y${GREEN}/${WHITE}n${GREEN}]${RESET}"
                read RESPONSE
                if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
                if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
                if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
                if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
                if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
                if [ "$RESPONSE" = "y" ]; then
                    echo -ne "${QUESTION_FLAG} Please type the name of the project?${RESET}
"
                    read PROJECT_NAME
                    touch CHANGELOG.md
                    echo "# Changelog $PROJECT_NAME" >> CHANGELOG.md
                    gsed -i "1 a\ " CHANGELOG.md
                    gsed -i "2 a ## [v0.1.0] ($NOW)\n" CHANGELOG.md
                fi
            fi

            #echo -e "$ADJUSTMENTS_MSG"
            #read
            echo -e "$PUSHING_MSG"
            git add VERSION
            git add CHANGELOG.md
            git commit -m "Add VERSION and CHANGELOG files, Bump version to v0.1.0."
            git tag -a -m "Tag version 0.1.0." "v0.1.0"
            git push origin --tags
        fi
    fi
fi

echo -e "${NOTICE_FLAG} Finished."

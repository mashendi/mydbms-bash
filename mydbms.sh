#!/bin/bash
#
#MYDBMS is a simple DBMS enables users to store and retrieve data from hard disk
#Author: Muhammed Atef Shendi
#Version: 1.0
#date: 9-1-2021

clear

echo " __  ____   ______  ____  __  __ ____"
echo "|  \/  \ \ / /  _ \| __ )|  \/  / ___|"
echo "| |\/| |\ V /| | | |  _ \| |\/| \___ \ "
echo "| |  | | | | | |_| | |_) | |  | |___) |"
echo "|_|  |_| |_| |____/|____/|_|  |_|____/ "
echo ""
echo "Written By: Shendi - muhammedshendi@gmail.com"
echo "Open Source 41 - Mansoura"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

rootLogin() {
    echo -e "${GREEN}"
    echo -e "Username: root"
    read -s -p "Password: " rootpasswd
    echo -e "${NC}"

    passwd=$(head -n 1 DBMS/root/.root)

    if [ "$rootpasswd" = "$passwd" ]; then
        mainMenu
    else
        echo -e "${RED}Wrong Password! try again...${NC}"
        rootLogin
    fi
}

function mainMenu() {
    echo ""
    PS3="mydbms>"
    options=("Create Database" "List Databases" "Connect to Database" "Drop Database" "Exit")
    select command in "${options[@]}"; do
        case $command in
        "Create Database") createDB ;;
        "List Databases") listDB ;;
        "Connect to Database") connectDB ;;
        "Drop Database") dropDB ;;
        "Exit") exit ;;
        *) echo -e "${RED}Wrong choice...${NC}" ;;
        esac
    done
}

function createDB() {
    echo -e "Enter Database name: \c"
    read -r dbname
    if mkdir -p Databases/"$dbname"; then
        echo -e "${GREEN}Database created successfully${NC}"
    else
        echo -e "${RED}Error creating database $dbname${NC}"
    fi
    mainMenu
}

function listDB() {
    count=$(ls Databases | wc -w)
    echo -e "${GREEN}Found $count Databases"
    echo -e "\nDatabases: \c"
    ls Databases 2> /dev/null
    echo -e "${NC}"
    mainMenu
}

function connectDB() {
    echo -e "Enter Database name: \c"
    read -r dbname
    if cd Databases/"$dbname" 2>/dev/null; then
        echo -e "${GREEN}Connected to $dbname database successflly${NC}"
        tablesMenu
    else
        echo -e "${RED}$dbname not found.${NC}"
        mainMenu
    fi
}

function dropDB() {
    echo -e "Enter Database name: \c"
    read -r dbname
    if [[ -d Databases/$dbname ]]; then
        if ! rm -rf Databases/"$dbname"; then
            echo -e "${RED}Database not found${NC}"
            mainMenu
        else
            echo -e "${GREEN}Database Dropped Successfully${NC}"
            mainMenu
        fi
    else
        echo -e "${RED}Wrong DB Name${NC}"
        mainMenu
    fi
}

function tablesMenu() {
    echo ""
    PS3="mydbms>"
    options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select from Table" "Delete from Table" "Back to Main Menu" "Exit")
    select command in "${options[@]}"; do
        case $command in
        "Create Table") createTable ;;
        "List Tables") listTables ;;
        "Drop Table") dropTable ;;
        "Insert into Table") insertIntoTable ;;
        "Select from Table") selectMenu ;;
        "Delete from Table") deleteFromTable ;;
        "Back to Main Menu")
            clear
            cd ../..
            mainMenu
            ;;
        "Exit") exit ;;
        *) echo -e "${RED}Wrong choice...${NC}" ;;
        esac
    done
}

function createTable() {
    sep=","
    rSep="\n"
    PK=""
    metaData="Feild${sep}Type${sep}Key"
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [ -f "$tableName" ]; then
        echo -e "${RED}Table already exists...${NC}"
        tablesMenu
    fi

    echo -e "Enter Column Names seperated by a space: \c"
    read -r -a columnNames

    for colName in "${columnNames[@]}"; do
        echo -e "Enter ${colName} datatype (num, str): \c"
        read -r columnDatatype

        if [[ $PK == "" ]]; then
            echo -e "Make it Primary Key ?"
            select rep in "yes" "no"; do
                case $rep in
                "yes")
                    PK="PK"
                    metaData+=$rSep$colName$sep$columnDatatype$sep$PK
                    break
                    ;;
                "no")
                    metaData+=$rSep$colName$sep$columnDatatype$sep""
                    break
                    ;;
                *) echo -e "${RED}Wrong choice...${NC}" ;;
                esac
            done
        else
            metaData+=$rSep$colName$sep$columnDatatype$sep""
        fi
    done

    touch ".${tableName}"
    echo -e "${metaData}" >>".${tableName}"

    if touch "$tableName"; then
        echo -e "${GREEN}Table ${tableName} Created Successfully${NC}"
        tablesMenu
    else
        echo -e "${RED}Error Creating Table $tableName${NC}"
        tablesMenu
    fi
}

function listTables() {
    count=$(ls | wc -w)
    if [ "$count" -eq 0 ]; then
        echo -e "${RED}Not Tables Found.${NC}"
        tablesMenu
    else
        echo -e "${GREEN}found ${count} Tables\n"
        ls
        echo -e "${NC}"
        tablesMenu
    fi
}

function dropTable() {
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [[ -f $tableName ]]; then
        if rm -f "$tableName"; then
            rm -f ".$tableName"
            echo -e "${GREEN}Table $tableName Deleted Successfully${NC}"
            tablesMenu
        else
            echo -e "${RED}Error Deleting Table${NC}"
            tablesMenu
        fi
    else
        echo -e "${RED}Wrong Table Name${NC}"
        tablesMenu
    fi

}

function insertIntoTable() {
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [ ! -f "$tableName" ]; then
        echo -e "${RED}Table not found${NC}"
        tablesMenu
    fi

    colsNum=$(awk 'END{print NR}' ".$tableName")
    sep=","
    rSep="\n"

    for ((i = 2; i <= "$colsNum"; i++)); do
        colName=$(awk -F , '{if (NR=='$i') print $1}' ".$tableName")
        colType=$(awk -F , '{if (NR=='$i') print $2}' ".$tableName")
        colKey=$(awk -F , '{if (NR=='$i') print $3}' ".$tableName")

        echo -e "$colName ($colType) = \c"
        read -r data

        # validate Input
        if [[ "$colType" == "num" ]]; then
            while [[ ! "$data" =~ ^[0-9]$ ]]; do
                echo -e "${RED}Invalid DataType${NC}\n"
                echo -e "$colName ($colType) = \c"
                read -r data
            done
        fi

        if [[ $colKey == "PK" ]]; then
            while true; do
                if [[ "$data" =~ ^[$(awk -F , 'BEGIN{ORS=" "}{if(NR != 1) print $(('$i' - 1))}' "$tableName")]$ ]]; then
                    echo -e "${RED}Invalid input${NC}"
                else
                    break
                fi
                echo -e "$colName ($colType) = \c"
                read -r data
            done
        fi

        if [[ "$i" == "$colsNum" ]]; then
            row=$row$data$rSep
        else
            row=$row$data$sep
        fi
    done
    if echo -e "$row\c" >>"$tableName"; then
        echo -e "${GREEN}Data Inserted Successfully${NC}"
    else
        echo -e "${RED}Error Inserting Data${NC}"
    fi
    row=""
    tablesMenu
}

function deleteFromTable() {
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [ ! -f "$tableName" ]; then
        echo -e "${RED}Table not found${NC}"
        tablesMenu
    fi

    echo -e "Enter Column Name: \c"
    read -r colName

    fid=$(awk -F ',' '{for(i=1;i<=NF;i++){if($i=="'"$colName"'") print NR - 1}}' ."$tableName")
    if [[ $fid == "" ]]; then
        echo -e "${RED}Not Found${NC}"
        selectMenu
    else
        echo -e "Enter Operator: \c"
        read -r op
        echo -e "Enter Value: \c"
        read -r val
        out=$(awk -F ',' 'BEGIN{ORS=","}{if($'$fid$op'"'$val'") print NR}' "$tableName")
        if [[ "$out" == "" ]]; then
            echo -e "${RED}Value Not Found${NC}"
            selectMenu
        else
            echo -e "${GREEN}"
            echo -e "---------------"
            out=$(echo $out | sed 's/,$//')
            count=$(echo $out | awk -F ',' 'BEGIN{sum=0}{for(i=1;i<=NF;i++) sum+=1} END{print sum}')
            sed -i ''$out'd' "$tableName"
            echo -e "$count Rows Deleted Successfully${NC}"
            tablesMenu
        fi
        echo -e "${RED}Error Deleting Records${NC}"

        tablesMenu
    fi

}

function selectMenu() {
    echo ""
    PS3="mydbms>"
    options=("Select All" "Select Column" "Select All With Condition" "Select With Condition" "Back to Tables Menu" "Back to Main Menu" "Exit")
    select command in "${options[@]}"; do
        case $command in
        "Select All") selectAll ;;
        "Select Column") selectColumn ;;
        "Select All With Condition") selectAllWithCondition ;;
        "Select With Condition") selectWithCondition ;;
        "Back to Tables Menu")
            clear
            tablesMenu
            ;;
        "Back to Main Menu")
            clear
            cd ../..
            mainMenu
            ;;
        "Exit") exit ;;
        *) echo -e "${RED}Wrong choice...${NC}" ;;
        esac
    done
    tablesMenu
}

function selectAll() {
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [ ! -f "$tableName" ]; then
        echo -e "${RED}Table not found${NC}"
        selectMenu
    fi

    echo -e "${GREEN}"
    awk -F ',' 'BEGIN{ORS=","}{if (NR > 1) print $1 }' ".$tableName" | column -t -s ','
    echo "---------------"
    if ! column -t -s ',' $tableName 2>/dev/null; then
        echo -e "${RED}Error Displaying $tableName Table${NC}"
    fi
    echo -e "${NC}"
    selectMenu

}

function selectColumn() {
    echo -e "Enter Table Name: \c"
    read -r tableName

    if [ ! -f "$tableName" ]; then
        echo -e "${RED}Table not found${NC}"
        selectMenu
    fi

    echo -e "Enter Column Name: \c"
    read -r columnName
    fid=$(awk -F ',' '{for(i=1;i<=NF;i++){if($i=="'"$columnName"'") print NR}}' ".$tableName")
    echo -e "${GREEN}"
    awk -F ',' '{for(i=1;i<=NF;i++){if($i=="'"$columnName"'") print $i}}' ".$tableName"
    echo -e "---------------"
    awk -F ',' '{print $'"(($fid - 1))"'}' "$tableName"
    echo -e "${NC}"
    selectMenu
}

function selectAllWithCondition() {
    echo -e "Enter Table Name: \c"
    read -r tableName
    echo -e "Enter Column Name: \c"
    read -r colName
    fid=$(awk -F ',' '{for(i=1;i<=NF;i++){if($i=="'"$colName"'") print NR - 1}}' ."$tableName")
    if [[ $fid == "" ]]; then
        echo -e "${RED}Not Found${NC}"
        selectMenu
    else
        echo -e "Enter Operator: \c"
        read -r op
        echo -e "Enter Value: \c"
        read -r val
        out=$(awk -F ',' '{if($'$fid$op'"'$val'") print $0}' "$tableName" | column -t -s ',')
        if [[ "$out" == "" ]]; then
            echo -e "${RED}Value Not Found${NC}"
            selectMenu
        else
            echo -e "${GREEN}"
            awk -F ',' 'BEGIN{ORS=","}{if (NR > 1) print $1 }' ".$tableName" | column -t -s ','
            echo "---------------"
            awk -F ',' '{if ($'$fid$op'"'$val'") print $0 }' "$tableName" | column -t -s ','
            echo -e "${NC}"
            selectMenu
        fi
        echo -e "${RED}Error Retrieving Records${NC}"
        selectMenu
    fi

}

function selectWithCondition() {
    echo -e "Enter Table Name: \c"
    read -r tableName
    echo -e "Enter Column Name: \c"
    read -r colName
    fid=$(awk -F ',' '{for(i=1;i<=NF;i++){if($i=="'"$colName"'") print NR - 1}}' ."$tableName")
    if [[ $fid == "" ]]; then
        echo -e "${RED}Not Found${NC}"
        selectMenu
    else
        echo -e "Enter Operator: \c"
        read -r op
        echo -e "Enter Value: \c"
        read -r val
        out=$(awk -F ',' '{if($'$fid$op'"'$val'") print $'"$fid"'}' "$tableName" | column -t -s ',')
        if [[ "$out" == "" ]]; then
            echo -e "${RED}Value Not Found${NC}"
            selectMenu
        else
            echo -e "${GREEN}"
            echo "$colName"
            echo "---------------"
            awk -F ',' '{if ($'$fid$op'"'$val'") print $'"$fid"' }' "$tableName" | column -t -s ','
            echo -e "${NC}"
            selectMenu
        fi
        echo -e "${RED}Error Retrieving Records${NC}"
        selectMenu
    fi

}

if [ ! -d DBMS ]; then
    mkdir -p DBMS/root
    touch DBMS/root/.root

    echo -e "${RED}This is your first time. you have to assign password to root user!${NC}"
    read -s -p "Password: " rootpasswd
    echo "$rootpasswd" >DBMS/root/.root
    echo -e "\n${RED}Restarting now...${NC}"
    sleep 3
    mkdir Databases
    ./mydbms.sh
else
    rootLogin
fi

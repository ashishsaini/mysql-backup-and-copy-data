#!/bin/bash

get_mysql_configs(){
	###get mysql credentials
	echo "-->MySQL hostname "
	read hostname

	echo "-->MySQL user "
	read user

	echo "-->MySQL password "
	read password

	echo "Checking database connection and showing databases..."
	mysql -h "$hostname" -u "$user" --password="$password" -e "show databases"

	echo "-->Use database "
        read database

    echo "Checking if database exists..."     
	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database"

	if [[ $? != 0 ]]; then
		echo "$(tput setaf 1)No database named $database !! Exiting..."
		exit
	fi

    echo "Showing database tables for selecting..."
	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; show tables;"

	echo "-->Table to be copied and renamed"
	read table

	echo "Checking tablename and show create table query..."
	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; show create table $table;"
	
	if [[ $? != 0 ]]; then
		echo "$(tput setaf 1)No Table named $table !! Exiting..."
		exit
	fi

	echo "$(tput setaf 2) MySQL credentials looks OK!"
}

process(){
	echo "$(tput setaf 2) The script will now do the following : "
	echo "$(tput setaf 2)1. Rename the table $table to $table""_bak, check if it does not exist already"
	echo "$(tput setaf 2)2. Create an empty table named $table"
	echo "$(tput setaf 2)3. It will ask if you need to copy some data from old table"

	echo "-->Backup table name"
	read old_table

	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; RENAME TABLE $table TO $old_table"

	if [[ $? != 0 ]]; then
		echo "$(tput setaf 1)Some Error in rename table !! Exiting..."
		exit
	fi

	echo "$(tput setaf 2) Success! Table renamed "

	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; CREATE TABLE $table LIKE $old_table"

	if [[ $? != 0 ]]; then
		echo "$(tput setaf 1)Some Error in creating table $table !! Exiting..."
		exit
	fi

	echo "$(tput setaf 2) Success! Table created "

	echo "-->$(tput setaf 5)Do you want to copy old data? y/n"
	read copy_data

	if [[ $copy_data == 'n' || $copy_data == 'N' ]]; then
		echo "$(tput setaf 1)Good Bye!"
		exit
	fi

	echo "It will run folowing query to copy the data : "
	echo " insert into $table select * from $old_table where {column} > {value}"
	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; show columns from $old_table"
	echo "-->select {column} name"
	read column

	echo "-->enter the {value} of $column after this value in $column data will be insterted in $table"
	echo "should have same format as $column"
	read value

	echo "$(tput setaf 2) Inserting the data in $table ..."
	mysql -h "$hostname" -u "$user" --password="$password" -e "use $database; insert into $table select * from $old_table where $column > '$value'"

	if [[ $? != 0 ]]; then
		echo "$(tput setaf 1)Some Error in inserting data into $table !! Exiting..."
		exit
	fi

	echo "$(tput setaf 2) Success! Its all done! Thanks!"

}


get_mysql_configs
process


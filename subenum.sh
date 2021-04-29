#!/bin/bash
#Author: sushant dhopat
#Basic subdomaain enum tool

echo -e "\e[1;32m
$(figlet Sushant Dhopat)
\e[0m "
echo " "
echo -e "\e[1;32m        Read about at https://github.com/sushantdhopat\e[0m"
echo -e "\e[1;32m                       By: Sushant Dhopat
                  Github: https://github.com/sushantdhopat       \e[0m"
echo " "
echo -e "\e[1;32m Run this script as root \e[0m"
echo -e "\e[1;32m <------------------------------------------------------------------------>\e[0m"

target=$1
#username=echo $USERNAME
mkdir new-$target
#passive subdomain enumeration
echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -passive -d $target | tee new-$target/$target-amass.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the sudomainizer \e[0m"
python3 ~/SubDomainizer/SubDomainizer.py -u https://www.$target -o new-$target/$target-subdomainizer.txt
#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt

rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-subdomainizer.txt
#sorting the uniq domains 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt

rm new-$target/allsub-$target.txt
echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/allsortedsub-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Finished all recon \e[0m"

#!/bin/bash
#Author: sushant dhopat
#Basic recon tool

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
wordlist=/home/sushant/words.txt
mkdir new-$target
mkdir new-$target/nuclei-$target
mkdir new-$target/dirsearch-$target
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
cat new-$target/*.txt > new-$target/all-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-subdomainizer.txt
echo -e "\e[1;34m [+] Enumerating permuted subdomains from the goaltdns \e[0m"
cat new-$target/all-$target.txt | goaltdns -w $wordlist | tee new-$target/permutedsub.txt
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/all-$target.txt new-$target/permutedsub.txt

#sorting the uniq domains 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt

rm new-$target/allsub-$target.txt
echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/allsortedsub-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Running nuclei-tempaltes takovers for possible subdomain takeover \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/takeovers | tee new-$target/possibletakeover-$target.txt
echo -e "\e[1;34m [+] Running all nuclei-templates for the recon \e[0m"
echo -e "\e[1;34m [+] Running nculei-templates cves \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/cves | tee new-$target/nuclei-$target/cves.txt
echo -e "\e[1;34m [+] Running nculei-templates deafult-login \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/default-logins | tee new-$target/nuclei-$target/default-login.txt
echo -e "\e[1;34m [+] Running nculei-templates dns \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/dns | tee new-$target/nuclei-$target/dns.txt
echo -e "\e[1;34m [+] Running nculei-templates exposed-panel \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/exposed-panels | tee new-$target/nuclei-$target/exposed-panel.txt
echo -e "\e[1;34m [+] Running nculei-templates exposers \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/exposures | tee new-$target/nuclei-$target/exposure.txt
echo -e "\e[1;34m [+] Running nculei-templates fuzzing \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/fuzzing | tee new-$target/nuclei-$target/fuzzing.txt
echo -e "\e[1;34m [+] Running nculei-templates headless \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/headless | tee new-$target/nuclei-$target/headless.txt
echo -e "\e[1;34m [+] Running nculei-templates helpers \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/helpers | tee new-$target/nuclei-$target/helpers.txt
echo -e "\e[1;34m [+] Running nculei-templates iot \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/iot | tee new-$target/nuclei-$target/iot.txt
echo -e "\e[1;34m [+] Running nculei-templates miscellaneous \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/miscellaneous | tee new-$target/nuclei-$target/miscellaneous.txt
echo -e "\e[1;34m [+] Running nculei-templates misconfiguration \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/misconfiguration | tee new-$target/nuclei-$target/misconfiguration.txt
echo -e "\e[1;34m [+] Running nculei-templates network \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/network | tee new-$target/nuclei-$target/network.txt
echo -e "\e[1;34m [+] Running nculei-templates technologies \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/technologies | tee new-$target/nuclei-$target/technologies.txt
echo -e "\e[1;34m [+] Running nculei-templates vulnerabilities \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/vulnerabilities | tee new-$target/nuclei-$target/vulnerabilities.txt
echo -e "\e[1;34m [+] Running nculei-templates workflow \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /home/sushant/nuclei-templates/workflows | tee new-$target/nuclei-$target/workflow.txt
echo -e "\e[1;34m [+] Nuclei recon finished \e[0m"
echo -e "\e[1;34m [+] Performing dirsearch for all subdomains  \e[0m"
python3 dirsearch/dirsearch.py -e php,htm,js,bak,zip,tgz,txt,asp -l new-$target/validsubdomain-$target.txt | tee new-$target/dirsearch-$target/files.txt

echo -e "\e[1;34m [+] Finished all recon \e[0m"

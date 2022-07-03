#! /bin/bash
#Author: sushant dhopat
#Basic subdomain recon tool
#Tools:-
#Assetfinder 
#subfinder
#amass
#sublist3r
#httpx
#subbrute
#gobuster

echo -e "\e[1;32m "
#Need resolvers you can get from amass you can also generate with shuffledns store them in specifc directory and add this directory path in resolver variable
resolver=/home/sushant/subbrute/resolver.txt #its a subbrute resolver path just pass your own path of subbrute tool
wordlist=/home/sushant/subdomains.txt #its a wordlist for bruteforce subdomain just pass any sub bruteforce wordlist
target=$1

if [ $# -gt 2 ]; then
       echo "./sub.sh <domain>"
       echo "./sub.sh google.com"
       exit 1
fi


if [ ! -d new-$target ]; then
       mkdir new-$target
 else
    echo "sorry we cant create the same file in same directory please remove first one new-$target !!!Thanks"
    exit 1

fi

#passive subdomain enumeration with different tool

echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -passive -d $target | tee new-$target/$target-amass.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the sublist3r \e[0m"
sublist3r -d $target -o new-$target/$target-sublist.txt

#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt
#new file generated new-$target/allsortedsub-$target.txt

#gathering third level domain
echo -e "\e[1;34m [+] compiling third level subdomain \e[0m"
cat new-$target/allsortedsub-$target.txt | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> new-$target/thirdlevel.txt

echo -e "\e[1;34m [+] Gathering all thirdlevel subdomain throw sublist3r \e[0m"

for domain in $(cat new-$target/thirdlevel.txt); do sublist3r -d $domain -o new-$target/$domain.txt | sort -u >> new-$target/final.txt;done
rm new-$target/thirdlevel.txt
#new file generated new-$target/final.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the subbrute \e[0m"
python3 /home/sushant/subbrute/subbrute.py $target -s new-$target/allsortedsub-$target.txt -r $resolver -o new-$target/$target-subbrute.txt
cat new-$target/*.txt > new-$target/allsubdomains.txt
rm new-$target/$target-subbrute.txt
cat new-$target/allsubdomains.txt | grep $target | sort -u | tee new-$target/new-allsub-$target.txt
rm new-$target/allsubdomains.txt
#new file is generated new-$target/new-allsub-$target.txt
echo -e "\e[1;34m [+] Bruteforcing Subdomain with gobuster \e[0m"
gobuster dns -d $target -w $wordlist -o new-$target/$target-brutesub.txt
cat new-$target/*.txt > new-$target/allfinalsub.txt
cat new-$target/allfinalsub.txt | sort -u | tee new-$target/allfinalsortedsub.txt
#new file generated new-$target/allfinalsortedsub.txt
rm new-$target/$target-brutesub.txt new-$target/allfinalsub.txt new-$target/allsortedsub-$target.txt new-$target/new-allsub-$target.txt new-$target/final.txt

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/allfinalsortedsub.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/allfinalsortedsub.txt | wc -w
echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/validsubdomain-$target.txt | wc -w
echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"

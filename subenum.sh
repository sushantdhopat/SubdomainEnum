#! /bin/bash
#Author: sushant dhopat
#Basic recon tool

echo -e "\e[1;32m "
resolver=/home/sushant/subbrute/resolvers.txt
target=$1
mkdir new-$target
#passive subdomain enumeration
echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -passive -d $target | tee new-$target/$target-amass.txt
#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt
#sorting the uniq domains 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt
echo -e "\e[1;34m [+] Enumerating Subdomain from the subbrute \e[0m"
python /home/sushant/subbrute/subbrute.py $target -s new-$target/allsortedsub-$target.txt -r $resolver -o new-$target/$target-subbrute.txt
cat new-$target/*.txt > new-$target/allsubdomains.txt
rm new-$target/allsortedsub-$target.txt new-$target/$target-subbrute.txt
cat new-$target/allsubdomains.txt | sort -u | tee new-$target/new-allsub-$target.txt
rm new-$target/allsubdomains.txt
echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/new-allsub-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt
echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/new-allsub-$target.txt | wc -w
echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/validsubdomain-$target.txt | wc -w
echo -e "\e[1;34m [+] Finished all recon \e[0m"

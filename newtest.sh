#! /bin/bash
#Author: sushant dhopat
#sub enum

echo -e "\e[1;32m "

target=$1
resolver=/root/resolvers.txt
wordlist=/root/all.txt
altdnswords=/root/altdns.txt

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

echo -e "\e[1;34m [+] Enumerating Subdomain from the assetfinder \e[0m"
echo $target | assetfinder -subs-only| tee new-$target/$target-assetfinder.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the subfinder \e[0m"
subfinder -d $target | tee new-$target/$target-subfinder.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the amass \e[0m"
amass enum -active -d $target -brute -w $wordlist -config /root/config.ini | tee new-$target/$target-amass.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the sublist3r \e[0m"
python3 /root/Sublist3r/sublist3r.py -d $target -o new-$target/$target-sublist.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the censys \e[0m"
python3 /Users/sushantdhopat/Desktop/censys-subdomain-finder/censys-subdomain-finder.py $target | tee new-$target/$target-censys.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the crt.sh \e[0m"
curl -s https://crt.sh/\?q\=$target\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee new-$target/$target-crt.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the wayback \e[0m"
curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$1&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | tee new-$target/$target-wayback.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the riddler.io \e[0m"
curl -s "https://riddler.io/search/exportcsv?q=pld:$1" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee new-$target/$target-riddler.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the virustottal \e[0m"
curl -s "https://www.virustotal.com/ui/domains/$1/subdomains?limit=40" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee new-$target/$target-virus.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the subbuster \e[0m"
curl -s "https://subbuster.cyberxplore.com/api/find?domain=$1" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | tee new-$target/$target-subbuster.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the certspotter \e[0m"
curl -s "https://certspotter.com/api/v1/issuances?domain=$1&include_subdomains=true&expand=dns_names" | jq .[].dns_names | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u  | tee new-$target/$target-certspotter.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the jldc.me \e[0m"
curl -s "https://jldc.me/anubis/subdomains/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee new-$target/$target-jldc.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the securitytrails \e[0m"
curl -s "https://securitytrails.com/list/apex_domain/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$1" | sort -u | tee new-$target/$target-securitytrails.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the sonar \e[0m"
curl -s "https://sonar.omnisint.io/subdomains/$1" | grep -oE "[a-zA-Z0-9._-]+\.$1" | sort -u | tee new-$target/$target-sonar.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the snapsint \e[0m"
curl -s -X POST "https://synapsint.com/report.php" -d "name=https%3A%2F%2F$1" | grep -oE "[a-zA-Z0-9._-]+\.$1" | sort -u | tee new-$target/$target-synapsint.txt


#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt new-$target/$target-crt.txt new-$target/$target-wayback.txt new-$target/$target-virus.txt new-$target/$target-certspotter.txt new-$target/$target-securitytrails.txt new-$target/$target-sonar.txt new-$target/$target-synapsint.txt new-$target/$target-subbuster.txt new-$target/$target-censys.txt new-$target/$target-jldc.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt

echo -e "\e[1;34m [+] Bruteforce subdomain throw puredns \e[0m"
puredns bruteforce -r $resolver $wordlist $target | tee new-$target/bruteforce-$target.txt

echo -e "\e[1;34m [+] Running dnsgen -perm \e[0m"
cat new-$target/allsortedsub-$target.txt | dnsgen - | tee new-$target/dnsgen-$target.txt

echo -e "\e[1;34m [+] Bruteforcing subdomains throw gotator \e[0m"
gotator -sub new-$target/allsortedsub-$target.txt -perm $perm -depth 3 -numbers 10 -md -prefixes -adv -mindup | uniq | tee new-$target/gotator-$target.txt

cat new-$target/*.txt > new-$target/unsortedresolve-$target.txt
rm new-$target/allsortedsub-$target.txt new-$target/bruteforce-$target.txt new-$target/dnsgen-$target.txt new-$target/gotator-$target.txt
cat new-$target/unsortedresolve-$target.txt | sort -u | tee new-$target/for-resolve-$target.txt
rm new-$target/unsortedresolve-$target.txt

echo -e "\e[1;34m [+] Resolving subdomain throw puredns \e[0m"
puredns resolve -r $resolver new-$target/for-resolve-$target.txt | tee new-$target/resolved-$target.txt

echo -e "\e[1;34m [+] Gathering IP address of resolved subdomain \e[0m"
bash /root/dtoip.sh new-$target/resolved-$target.txt new-$target/ips.txt

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/for-resolve-$target.txt | httpx -silent | tee new-$target/validsubdomain-$target.txt

echo -e "\e[1;34m [+] performing screesnhots live hosts  \e[0m"
gowitness -F file -f new-$target/validsubdomain-$target.txt -p new-$target/validdomainscreenshots

echo -e "\e[1;34m [+] performing screesnhots on IPs  \e[0m"
gowitness -F file -f new-$target/ips.txt -p new-$target/resolvedipscreenshots

echo -e "\e[1;34m [+] Running ffuf on validsubdomain \e[0m"
ffuf -u W2/W1 -w /$fuzz:W1,/new-$target/validsubdomain-$target.txt:W2 -fc 204,301,302,307,401,403,405,500 -fs 0 -acc www | tee new-$target/ffufresult

echo -e "\e[1;34m [+] Running nuclie-templates on validsubdomain \e[0m"
cat new-$target/validsubdomain-$target.txt | nuclei -t /root/nuclei-templates | tee tee new-$target/nuclei

echo -e "\e[1;34m [+] performing nmap scan on resoved ip  \e[0m"
nmap -p 1-65535 -sV -iL new-$target/ips.txt -oN new-$target/ipscanoutput.txt -oX new-$target/ipscanoutput.xml
echo -e "\e[1;34m [+] performing nmap scan on resolved domains  \e[0m"
nmap -p 1-65535 -sV -iL new-$target/resolved-$target.txt -oN new-$target/domainscanoutput.txt -oX new-$target/domainscanoutput.xml

echo -e "\e[1;34m [+] performing screesnhots on open nmap ports  \e[0m"
gowitness nmap -F -f new-$target/ipscanoutput.xml --open --service-contains http -p new-$target/ipscanoutputscreenshots
gowitness nmap -F -f new-$target/domainscanoutput.xml --open --service-contains http -p new-$target/domainscanoutputscreenshots

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/for-resolve-$target.txt | wc -w

echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/validsubdomain-$target.txt | wc -w

echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"

#! /bin/bash
#Author: sushant dhopat
#sub enum
echo -e "\e[1;32m "
target=$1
wordlist=/root/best-dns-wordlist.txt
altdnswords=/root/altdns.txt
perm=/root/dirbrut/perm-word.txt
resolver=/root/resolvers.txt

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
python3 /root/censys-subdomain-finder/censys-subdomain-finder.py $target | tee new-$target/$target-censys.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the github \e[0m"
github-subdomains -d $target | tee new-$target/$target-github.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the crt.sh \e[0m"
curl -s https://crt.sh/\?q\=$target\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u | tee new-$target/$target-crt.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the wayback \e[0m"
curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$1&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | tee new-$target/$target-wayback.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the riddler.io \e[0m"
curl -s "https://riddler.io/search/exportcsv?q=pld:$1" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee new-$target/$target-riddler.txt

echo -e "\e[1;34m [+] Enumerating Subdomain from the securitytrails \e[0m"
curl -s "https://securitytrails.com/list/apex_domain/$1" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$1" | sort -u | tee new-$target/$target-securitytrails.txt

#copy above all different files finded subdomain in one spefic file
cat new-$target/*.txt > new-$target/allsub-$target.txt
rm new-$target/$target-assetfinder.txt new-$target/$target-subfinder.txt new-$target/$target-amass.txt new-$target/$target-sublist.txt new-$target/$target-crt.txt new-$target/$target-wayback.txt new-$target/$target-securitytrails.txt new-$target/$target-censys.txt new-$target/$target-riddler.txt new-$target/$target-github.txt
#sorting the uniq domains
 
cat new-$target/allsub-$target.txt | sort -u | tee new-$target/allsortedsub-$target.txt
rm new-$target/allsub-$target.txt

echo -e "\e[1;34m [+] Bruteforce subdomain throw puredns \e[0m"
puredns bruteforce -r $resolver $wordlist $target | tee new-$target/bruteforce-$target.txt

echo -e "\e[1;34m [+] Bruteforce subdomain throw altdns \e[0m"
altdns -i new-$target/allsortedsub-$target.txt -o new-$target -w $perm -r -s new-$target/results_output.txt

echo -e "\e[1;34m [+] Running dnsgen -perm \e[0m"
cat new-$target/allsortedsub-$target.txt | dnsgen -w $wordlist - | tee new-$target/dnsgen-$target.txt

echo -e "\e[1;34m [+] Running gotator -perm \e[0m"
timeout 10h gotator -sub new-$target/allsortedsub-$target.txt -perm $perm -depth 3 -numbers 10 -md | uniq | tee new-$target/gotator-$target.txt

cat new-$target/*.txt > new-$target/unsortedresolve-$target.txt
rm new-$target/allsortedsub-$target.txt new-$target/bruteforce-$target.txt new-$target/dnsgen-$target.txt new-$target/results_output.txt new-$target/gotator-$target.txt
cat new-$target/unsortedresolve-$target.txt | sort -u | tee new-$target/for-resolve-$target.txt
rm new-$target/unsortedresolve-$target.txt

echo -e "\e[1;34m [+] Resolving subdomain throw puredns \e[0m"
puredns resolve -r $resolver new-$target/for-resolve-$target.txt | tee new-$target/resolved-$target.txt

echo -e "\e[1;34m [+] Gathering IP address of resolved subdomain \e[0m"
bash /root/dtoip.sh new-$target/resolved-$target.txt new-$target/ips.txt

mkdir new-$target/valid

echo -e "\e[1;34m [+] Running Httpx for live host \e[0m"
cat new-$target/for-resolve-$target.txt | httpx -silent | tee new-$target/valid/validsubdomain-$target.txt

echo -e "\e[1;34m [+] Running Httpx for live ips \e[0m"
cat new-$target/ips.txt | httpx -silent | tee new-$target/valid/validips-$target.txt

echo -e "\e[1;34m [+] Gathering technologies fro valid domains \e[0m"
mkdir new-$target/tech
webanalyze -hosts new-$target/valid/validsubdomain-$target.txt | tee new-$target/tech/validsubtech.txt
webanalyze -hosts new-$target/valid/validips-$target.txt | tee new-$target/tech/validiptech.txt

echo -e "\e[1;34m [+] performing nuclei scan on valid subdomains \e[0m"

mkdir new-$target/nuclei

cat new-$target/valid/validsubdomain-$target.txt | nuclei -severity critical -t /root/nuclei-templates -o new-$target/nuclei/critical
cat new-$target/nuclei/critical | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/valid/validsubdomain-$target.txt | nuclei -severity high -t /root/nuclei-templates -o new-$target/nuclei/high
cat new-$target/nuclei/high | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/valid/validsubdomain-$target.txt | nuclei -severity medium -t /root/nuclei-templates -o new-$target/nuclei/medium
cat new-$target/nuclei/medium | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/valid/validsubdomain-$target.txt | nuclei -severity low -t /root/nuclei-templates -o new-$target/nuclei/low
cat new-$target/nuclei/low | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l

echo -e "\e[1;34m [+] performing wayback for collecting waybackurls  \e[0m"

mkdir new-$target/wayback

cat new-$target/valid/validsubdomain-$target.txt | gau | tee new-$target/wayback/gau.txt
cat new-$target/valid/validsubdomain-$target.txt | waybackurls | tee new-$target/wayback/wayback.txt
cat new-$target/wayback/gau.txt new-$target/wayback/wayback.txt >> new-$target/wayback/allurl.txt
rm new-$target/wayback/gau.txt new-$target/wayback/wayback.txt
cat new-$target/wayback/allurl.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
sleep 5
#api endpoint 
echo -e "Starting Collect Api-Endpoint"
cat new-$target/wayback/allurl.txt | grep -i "/api/" | sort -u | tee new-$target/wayback/apiend.txt
cat Subdomains/API_EndPoint/Api-EndPoint.txt  | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
sleep 5

echo -e "\e[1;34m [+] performing Js files scan  \e[0m"

mkdir new-$target/jsfile
echo -e "Collect js,php,jsp,aspx File"

cat new-$target/wayback/allurl.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u| grep -aEi "\.(js)" | tee new-$target/jsfile/Js-file.txt
cat new-$target/jsfile/Js-file.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/wayback/allurl.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u| grep -aEi "\.(php)" | tee new-$target/jsfile/PHP-file.txt
cat new-$target/jsfile/PHP-file.txt  | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/wayback/allurl.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u| grep -aEi "\.(aspx)" | tee new-$target/jsfile/aspx-file.txt
cat new-$target/jsfile/aspx-file.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
cat new-$target/wayback/allurl.txt | grep -aEo 'https?://[^ ]+' | sed 's/]$//' | sort -u| grep -aEi "\.(jsp)" | tee new-$target/jsfile/Jsp-file.txt
cat new-$target/jsfile/Jsp-file.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l

echo -e "Start Filter Js file"

cat new-$target/jsfile/Js-file.txt | sort -u | httpx -content-type | grep 'application/javascript' | cut -d' ' -f1 > new-$target/jsfile/Js-file200.txt
cat new-$target/jsfile/Js-file200.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
httpx -l new-$target/jsfile/Js-file200.txt -match-string "js.map" -o new-$target/jsfile/Jsmap.txt

echo -e "Starting Js Scan"

cat new-$target/jsfile/Js-file200.txt | nuclei -t /root/nuclei-templates/exposures/ -o new-$target/jsfile/nucleijs.txt
cat new-$target/jsfile/nucleijs.txt | tr '[:upper:]' '[:lower:]'| anew | grep -v " "|grep -v "@" | grep "\." | wc -l
#after collect key run these comannd on key nuclei -t $HOME/nuclei-templates/token-spray -var token=vt70wYM90ZixRqNPSqYC2FLokqpcZsYqvwc5NS04z6pIibNI63M814r

echo -e "\e[1;34m [+] performing param discovery  \e[0m"
mkdir new-$target/param

echo -e "Start Parameter Discovery"
for x in $(cat new-$target/valid/validsubdomain-$target.txt )
do
python3 /root/ParamSpider/paramspider.py  --domain $x -o new-$target/param/param
done
cat new-$target/param/param/* > new-$target/param/params.txt
cat new-$target/param/params.txt | sort -u | tee cat new-$target/param/finalparams.txt
rm new-$target/param/params.txt

echo -e "performing XRAY scan on founded param"
mkdir new-$target/xray
for x in $(cat new-$target/param/finalparams.txt )
do
/root/xray webscan --url $x --plugins xss,sqldet,cmd-injection,path-traversal,xxe,jsonp,ssrf,baseline,redirect,crlf-injection --json-output new-$target/xray/result.json

echo -e "running http request smuggler"
cat new-$target/valid/validsubdomain-$target.txt | python3 /root/smuggler/smuggler.py


echo -e "performing CRLF fuzz"
mkdir new-$target/crlf
crlfuzz -l new-$target/valid/validsubdomain-$target.txt -o new-$target/crlf/result.txt

echo -e "gathering some valid service on valid domains"
mkdir new-$target/service
dnsx -silent -l new-$target/valid/validsubdomain-$target.txt -w jira,grafana,jenkins -o new-$target/service/service.txt

mkdir new-$target/screenshots
echo -e "\e[1;34m [+] performing screesnhots live hosts  \e[0m"
cat new-$target/valid/validsubdomain-$target.txt | aquatone -out new-$target/screenshots/$target.1
echo -e "\e[1;34m [+] performing screesnhots on IPs  \e[0m"
cat new-$target/valid/validips-$target.txt | aquatone -out new-$target/screenshots/$target.2

echo -e "\e[1;34m [+] Total Founded subdomains \e[0m"
cat new-$target/for-resolve-$target.txt | wc -w

echo -e "\e[1;34m [+] Total Founded valid subdomains \e[0m"
cat new-$target/valid/validsubdomain-$target.txt | wc -w

echo -e "[+] Finished all recon see your outpute generated on \e[1;34m new-$target \e[0m dir"

#!/bin/sh

cp /etc/config/youtubeUnblock /etc/config/youtubeUnblock.bak

cat > /etc/config/youtubeUnblock << 'EOF'
config youtubeUnblock 'youtubeUnblock'
	option conf_strat 'ui_flags'
	option packet_mark '32768'
	option queue_num '537'
	option no_ipv6 '1'
EOF

URLS="
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Categories/anime.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Categories/block.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Categories/news.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Categories/porn.lst
https://raw.githubusercontent.com/GhostRooter0953/discord-voice-ips/refs/heads/master/main_domains/discord-main-domains-list
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/hdrezka.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/meta.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/tiktok.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/twitter.lst
https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Services/youtube.lst
https://raw.githubusercontent.com/HotCakeX/MicrosoftDomains/refs/heads/main/Microsoft%%20Domains.txt
"

for url in $URLS; do
    echo "Processing $url..."
    
    author=$(echo "$url" | cut -d'/' -f4)
    filename=$(echo "$url" | awk -F/ '{print $NF}' | sed 's/.lst$//;s/.txt$//;s/%20/_/g')
    
    if [ "$filename" = "Microsoft_Domains" ]; then
        final_name="xbox-full-list"
    else
        final_name="${filename}-${author}"
    fi
    
    if ! curl -s -o /tmp/temp_list.txt "$url"; then
        echo "Error downloading $url"
        continue
    fi
    
    cat >> /etc/config/youtubeUnblock << EOF

config section
	option name '$final_name'
	option tls_enabled '1'
	option fake_sni '1'
	option faking_strategy 'pastseq'
	option fake_sni_seq_len '1'
	option fake_sni_type 'default'
	option frag 'tcp'
	option frag_sni_reverse '1'
	option frag_sni_faked '0'
	option frag_middle_sni '1'
	option frag_sni_pos '1'
	option seg2delay '0'
	option fk_winsize '0'
	option synfake '0'
	option all_domains '0'
EOF

    if [ "$final_name" = "discord-main-domains-list-GhostRooter0953" ]; then
        echo "	list udp_dport_filter '50000-50100'" >> /etc/config/youtubeUnblock
    fi

    if [ "$final_name" = "youtube-itdoginfo" ]; then
        echo "	option quic_drop '1'" >> /etc/config/youtubeUnblock
    fi

    cat >> /etc/config/youtubeUnblock << EOF
	option sni_detection 'parse'
	option udp_mode 'fake'
	option udp_faking_strategy 'none'
	option udp_fake_seq_len '6'
	option udp_fake_len '64'
	option udp_filter_quic 'disabled'
	option enabled '1'
EOF

    while read -r domain; do
        [ -n "$domain" ] && echo "	list sni_domains '$domain'" >> /etc/config/youtubeUnblock
    done < /tmp/temp_list.txt

    case $final_name in
        "hdrezka-itdoginfo")
            echo "	list sni_domains 'hdrezka.es'" >> /etc/config/youtubeUnblock
            ;;
        "youtube-itdoginfo")
            echo "	list sni_domains 'play.google.com'" >> /etc/config/youtubeUnblock
            ;;
        "Microsoft-Domains-HotCakeX")
            echo "	list udp_dport_filter '88,3074,53,80,500,3544,4500'" >> /etc/config/youtubeUnblock
            ;;
    esac

    rm -f /tmp/temp_list.txt
done

echo "Configuration saved to /etc/config/youtubeUnblock"

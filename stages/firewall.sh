do_firewall() {
  section "Applying nftables config"

  NFTABLES_CONFIG_FILE=/mnt/etc/nftables.conf
  CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs"

  cp "$CONFIG_DIR/99-hardened-nftables.conf" "$NFTABLES_CONFIG_FILE"

  log "Configuring interface ${FW_IFACE}"
  sed -i "s|FW_IFACE|${FW_IFACE}|g" "$NFTABLES_CONFIG_FILE"

  local inbound_rules=""

  local icmp_enabled icmp_rate
  icmp_enabled=$(cfg '.firewall.icmp.enabled')
  icmp_rate=$(cfg '.firewall.icmp.rate')

  if [[ "$icmp_enabled" == "true" ]]; then
    inbound_rules+="        ip protocol icmp limit rate ${icmp_rate} accept\n"
    inbound_rules+="        ip6 nexthdr icmpv6 limit rate ${icmp_rate} accept\n"
  fi

  local count
  count=$(cfg '.firewall.inbound | length')

  for ((i=0; i<count; i++)); do
    local proto dport saddr rate comment rule
    proto=$(cfg ".firewall.inbound[$i].proto")
    dport=$(cfg ".firewall.inbound[$i].dport")
    saddr=$(cfg ".firewall.inbound[$i].saddr")
    rate=$(cfg ".firewall.inbound[$i].rate")
    comment=$(cfg ".firewall.inbound[$i].comment")

    rule="        iif \"${FW_IFACE}\""
    [[ "$saddr" != "null" ]] && rule+=" ip saddr ${saddr}"
    rule+=" ${proto} dport ${dport}"
    [[ "$rate" != "null" ]] && rule+=" ct state new limit rate ${rate}"
    rule+=" accept"
    [[ "$comment" != "null" ]] && rule+=" comment \"${comment}\""

    inbound_rules+="${rule}\n"
  done

  local outbound_rules=""
  count=$(cfg '.firewall.outbound | length')

  for ((i=0; i<count; i++)); do
    local proto dport comment daddr_count
    proto=$(cfg ".firewall.outbound[$i].proto")
    dport=$(cfg ".firewall.outbound[$i].dport")
    comment=$(cfg ".firewall.outbound[$i].comment")
    daddr_count=$(cfg ".firewall.outbound[$i].daddr | length")

    if [[ "$daddr_count" -eq 0 ]]; then
      local rule="        oif \"${FW_IFACE}\" ${proto} dport ${dport} accept"
      [[ "$comment" != "null" ]] && rule+=" comment \"${comment}\""
      outbound_rules+="${rule}\n"
    else
      for ((j=0; j<daddr_count; j++)); do
        local ip rule
        ip=$(cfg ".firewall.outbound[$i].daddr[$j]")
        rule="        oif \"${FW_IFACE}\" ip daddr ${ip} ${proto} dport ${dport} accept"
        [[ "$comment" != "null" ]] && rule+=" comment \"${comment}\""
        outbound_rules+="${rule}\n"
      done
    fi
  done

  local tmp_file
  tmp_file=$(mktemp)

  awk -v rules="$inbound_rules" '{gsub(/        INBOUND_RULES/, rules)}1' \
    "$NFTABLES_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$NFTABLES_CONFIG_FILE"

  awk -v rules="$outbound_rules" '{gsub(/        OUTBOUND_RULES/, rules)}1' \
    "$NFTABLES_CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$NFTABLES_CONFIG_FILE"

  chmod 600 "$NFTABLES_CONFIG_FILE"

  log "nftables config applied"
  return 0
}
END=12
for ((i=1;i<=END;i++)); do
    curl -X 'GET' \
      "https://deep-index.moralis.io/api/v2/nft/0x882A47e6070acA3f38Ce6929501F4787803A072b/owners?chain=eth&format=decimal&offset=${i}" \
      -H "accept: application/json" \
      -H "X-API-Key: <api_key>"
done

#!/usr/bin/env bash

mkdir -p imports/kps/charts imports/kps/git

mkdir -p tmp && cd tmp

curl https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/grafana-dashboardDefinitions.yaml > dump.yaml

yq '.items[]' dump.yaml -s '.metadata.name'

ls | grep "grafana-dashboard" | while read file ; do
outputFile=$(echo "$file" | sed 's|grafana-dashboard-||' | sed 's|.yml|.json|')
yq -r '.data[]' $file | jq -r --sort-keys > ../imports/kps/git/$outputFile
done

cd -

rm -rf tmp

mkdir -p tmp && cd tmp

helm pull --repo https://prometheus-community.github.io/helm-charts kube-prometheus-stack --untar 

helm template kube-prometheus-stack --set-json='windowsMonitoring.enabled="true"' | yq 'select(.kind == "ConfigMap")' | yq 'select(.metadata.labels.app == "kube-prometheus-stack-grafana")' > dashboard-configmaps.yaml

yq -s '.metadata.name' dashboard-configmaps.yaml

ls | grep "release-name-kube-promethe" | while read file ; do
outputFile=$(echo "$file" | sed 's|release-name-kube-promethe-||' | sed 's|.yml|.json|')
yq -r '.data[]' $file | jq -r --sort-keys > ../imports/kps/charts/$outputFile
done

cd -

rm -rf tmp

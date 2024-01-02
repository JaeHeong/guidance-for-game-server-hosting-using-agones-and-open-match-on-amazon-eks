## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
## SPDX-License-Identifier: MIT-0
export GAMESERVER_TYPE=ncat 
export NAMESPACE=gameservers
export CLUSTER_NAME1=$1
export AWS_REGION=$2
export AWS_REGION1=$2
export CLUSTER_NAME2=$3
export AWS_REGION2=$4
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export REGISTRY=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION1}.amazonaws.com


aws ecr get-login-password --region ${AWS_REGION1} | docker login --username AWS --password-stdin $REGISTRY
docker build  -t $REGISTRY/agones-openmatch-ncat-server integration/ncat-server
docker push $REGISTRY/agones-openmatch-ncat-server

kubectl config use-context $(kubectl config get-contexts -o=name | grep ${CLUSTER_NAME1})
export AWS_REGION=$AWS_REGION1
echo "- Deploy fleets to cluster ${CLUSTER_NAME1} -"
for f in manifests/fleets/${GAMESERVER_TYPE}/*
do
    envsubst < $f  | kubectl apply --namespace ${NAMESPACE} -f -
done
echo
echo "- Display fleets and game servers -"
kubectl get fleets --namespace ${NAMESPACE}
kubectl get gameservers --namespace ${NAMESPACE} --show-labels
echo

kubectl config use-context $(kubectl config get-contexts -o=name | grep ${CLUSTER_NAME2})
export AWS_REGION=$AWS_REGION2
echo "- Deploy fleets to cluster ${CLUSTER_NAME2} -"
for f in manifests/fleets/${GAMESERVER_TYPE}/*
do
    envsubst < $f  | kubectl apply --namespace ${NAMESPACE} -f -
done
echo
# echo "- Display fleets and game servers -"
kubectl get fleets --namespace ${NAMESPACE}
kubectl get gameservers --namespace ${NAMESPACE} --show-labels
echo
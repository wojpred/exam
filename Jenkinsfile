node {
  def acr = 'acrdemo99.azurecr.io/apka:1'
  def appName = 'apka'
  def imageName = "${acr}/${appName}"
  def imageTag = "${imageName}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
  def appRepo = "acrdemo99.azurecr.io/apka:1"

  checkout scm
  
 stage('Build the Image and Push to Azure Container Registry') 
 {
   app = docker.build("${imageName}")
   withDockerRegistry([credentialsId: 'az-auth', url: "https://${acr}"]) {
      app.push("${env.BRANCH_NAME}.${env.BUILD_NUMBER}")
                }
  }

 stage ("Deploy Application on Azure Kubernetes Service")
 {
  switch (env.BRANCH_NAME) {
    // Roll out to canary environment
    case "canary":
        // Change deployed image in canary to the one we just built
        sh("kubectl get ns ${appName}-${env.BRANCH_NAME} || kubectl create ns ${appName}-${env.BRANCH_NAME}")
        withCredentials([usernamePassword(credentialsId: 'dupa1-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        sh "kubectl -n ${appName}-${env.BRANCH_NAME} get secret az-auth || kubectl --namespace=${appName}-${env.BRANCH_NAME} create secret docker-registry az-auth --docker-server ${acr} --docker-username $USERNAME --docker-password $PASSWORD"
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./canary/*.yml")
        sh("kubectl --namespace=canary apply -f ./services/")
        sh("kubectl --namespace=canary apply -f ./canary/")
        sh("echo http://`kubectl --namespace=canary get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break
          
    // Roll out to production
    case "master":
        // Change deployed image in master to the one we just built
        sh("kubectl get ns ${appName}-${env.BRANCH_NAME} || kubectl create ns ${appName}-${env.BRANCH_NAME}")
        withCredentials([usernamePassword(credentialsId: 'az-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        sh "kubectl -n ${appName}-${env.BRANCH_NAME} get secret az-auth || kubectl --namespace=${appName}-${env.BRANCH_NAME} create secret docker-registry az-auth --docker-server ${acr} --docker-username $USERNAME --docker-password $PASSWORD"
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./production/*.yml")
        sh("kubectl --namespace=prod apply -f ./services/")
        sh("kubectl --namespace=prod apply -f ./production/")
        sh("echo http://`kubectl --namespace=prod get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break

    // Roll out a dev environment
    default:
        // Create namespace if it doesn't exist
        sh("kubectl get ns ${appName}-${env.BRANCH_NAME} || kubectl create ns ${appName}-${env.BRANCH_NAME}")
        withCredentials([usernamePassword(credentialsId: 'az-auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        sh "kubectl -n ${appName}-${env.BRANCH_NAME} get secret az-auth || kubectl --namespace=${appName}-${env.BRANCH_NAME} create secret docker-registry az-auth --docker-server ${acr} --docker-username $USERNAME --docker-password $PASSWORD"
        // Don't use public load balancing for development branches
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./dev/*.yml")
        sh("kubectl --namespace=${appName}-${env.BRANCH_NAME} apply -f ./dev/")
        echo 'To access your environment run `kubectl proxy`'
        echo "Then access your service via http://localhost:8001/api/v1/proxy/namespaces/${appName}-${env.BRANCH_NAME}/services/${appName}:80"     
    }
  }
}

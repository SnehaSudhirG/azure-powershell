if(($null -eq $TestName) -or ($TestName -contains 'New-AzCdnCustomDomain'))
{
  $loadEnvPath = Join-Path $PSScriptRoot 'loadEnv.ps1'
  if (-Not (Test-Path -Path $loadEnvPath)) {
      $loadEnvPath = Join-Path $PSScriptRoot '..\loadEnv.ps1'
  }
  . ($loadEnvPath)
  $TestRecordingFile = Join-Path $PSScriptRoot 'New-AzCdnCustomDomain.Recording.json'
  $currentPath = $PSScriptRoot
  while(-not $mockingPath) {
      $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
      $currentPath = Split-Path -Path $currentPath -Parent
  }
  . ($mockingPath | Select-Object -First 1).FullName
}

Describe 'New-AzCdnCustomDomain' {
    It 'CreateExpanded' {
        { 
            $subId = "27cafca8-b9a4-4264-b399-45d0c9cca1ab"
            $ResourceGroupName = 'testps-rg-' + (RandomString -allChars $false -len 6)
            try
            {
                Write-Host -ForegroundColor Green "Create test group $($ResourceGroupName)"
                New-AzResourceGroup -Name $ResourceGroupName -Location $env.location -SubscriptionId $subId

                $cdnProfileName = 'p-' + (RandomString -allChars $false -len 6);
                Write-Host -ForegroundColor Green "Use cdnProfileName : $($cdnProfileName)"

                $profileSku = "Standard_Microsoft";
                New-AzCdnProfile -SkuName $profileSku -Name $cdnProfileName -ResourceGroupName $ResourceGroupName -Location Global -SubscriptionId $subId
                
                # Hard-coding host and endpoint names due to requirement for DNS CNAME
                $endpointName = 'e-20220407-52wg49'
                $customDomainHostName = 'e-20220407-52wg49.ps.cdne2e.azfdtest.xyz'
                $customDomainName = 'cd-' + (RandomString -allChars $false -len 6);
                $origin = @{
                    Name = "origin1"
                    HostName = "host1.hello.com"
                };
                $location = "westus"
                Write-Host -ForegroundColor Green "Create endpointName : $($endpointName), origin.Name : $($origin.Name), origin.HostName : $($origin.HostName)"

                New-AzCdnEndpoint -Name $endpointName -ResourceGroupName $ResourceGroupName -ProfileName $cdnProfileName -Location $location -Origin $origin -SubscriptionId $subId
                $customDomain = New-AzCdnCustomDomain -EndpointName $endpointName -Name $customDomainName -ProfileName $cdnProfileName -ResourceGroupName $ResourceGroupName -HostName $customDomainHostName -SubscriptionId $subId

                $customDomain.Name | Should -Be $customDomainName
                $customDomain.HostName | Should -Be $customDomainHostName
            } Finally
            {
                Remove-AzResourceGroup -Name $ResourceGroupName -SubscriptionId $subId -NoWait
            }
        } | Should -Not -Throw
    }
}

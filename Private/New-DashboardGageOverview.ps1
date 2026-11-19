function New-DashboardGageOverview {
    <#
    .SYNOPSIS
    Renders the gauge row and an optional city selector.
    .PARAMETER OverallGages
    Gauges without a city, shown in the All view when supplied.
    .PARAMETER CityGages
    Gauges grouped into selectable city views.
    #>
    [CmdletBinding()]
    param(
        [Array] $OverallGages,
        [Array] $CityGages
    )

    $RenderGages = {
        param($Gages)
        New-HTMLSection -Invisible {
            foreach ($Gage in $Gages) {
                New-HTMLPanel {
                    New-HTMLGage -Label $Gage.Label -MinValue $Gage.MinValue -MaxValue $Gage.MaxValue -Value $Gage.Value -Counter
                }
            }
        }
    }

    $Cities = @($CityGages | Group-Object -Property { $_['City'] } | Sort-Object -Property Name)
    if (-not $Cities.Count) {
        & $RenderGages $OverallGages
        return
    }

    Add-HTMLStyle -Content @'
.dashboard-gage-filter {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    font-size: .875rem;
    gap: .5rem;
    padding: .65rem 1rem .25rem;
}
.dashboard-gage-filter select {
    font: inherit;
    min-height: 2.25rem;
    max-width: 100%;
    padding-inline: .5rem;
}
.dashboard-gage-city-heading {
    font-size: 1rem;
    margin: .5rem 1rem 0;
}
'@
    New-HTMLTag -Tag 'div' -Attributes @{ id = 'dashboard-gage-overview' } {
        New-HTMLTag -Tag 'div' -Attributes @{ class = 'dashboard-gage-filter' } {
            New-HTMLTag -Tag 'label' -Attributes @{ for = 'dashboard-gage-city' } { 'City' }
            New-HTMLTag -Tag 'select' -Attributes @{ id = 'dashboard-gage-city' } {
                New-HTMLTag -Tag 'option' -Attributes @{ value = 'all'; selected = 'selected' } { 'All' }
                for ($Index = 0; $Index -lt $Cities.Count; $Index++) {
                    New-HTMLTag -Tag 'option' -Attributes @{ value = "city-$Index" } {
                        [Net.WebUtility]::HtmlEncode($Cities[$Index].Name)
                    }
                }
            }
        }
        if ($OverallGages.Count) {
            New-HTMLTag -Tag 'div' -Attributes @{ 'data-gage-scope' = 'all' } {
                & $RenderGages $OverallGages
            }
        }
        for ($Index = 0; $Index -lt $Cities.Count; $Index++) {
            $Attributes = @{ 'data-gage-scope' = "city-$Index" }
            if ($OverallGages.Count) {
                $Attributes.hidden = 'hidden'
            }
            New-HTMLTag -Tag 'div' -Attributes $Attributes {
                if (-not $OverallGages.Count) {
                    New-HTMLTag -Tag 'h3' -Attributes @{ class = 'dashboard-gage-city-heading' } {
                        [Net.WebUtility]::HtmlEncode($Cities[$Index].Name)
                    }
                }
                & $RenderGages $Cities[$Index].Group
            }
        }
    }
    Add-HTMLScript -Placement Footer -Content @'
(function () {
    const overview = document.getElementById("dashboard-gage-overview");
    const selector = document.getElementById("dashboard-gage-city");
    const groups = overview.querySelectorAll("[data-gage-scope]");
    const hasOverall = overview.querySelector('[data-gage-scope="all"]') !== null;

    function showSelectedGages() {
        const selected = selector.value;
        groups.forEach(group => {
            group.hidden = group.dataset.gageScope !== selected && (selected !== "all" || hasOverall);
        });
    }

    selector.addEventListener("change", showSelectedGages);
    showSelectedGages();
})();
'@
}

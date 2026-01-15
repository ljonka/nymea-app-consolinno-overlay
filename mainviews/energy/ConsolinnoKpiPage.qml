import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.2
import Nymea 1.0
import "qrc:/ui/components/"

Page {
    id: root
    property HemsManager hemsManager
    property string currentShortcut: "today"
    property date customStartDate: new Date()
    property date customEndDate: new Date()
    
    property var summaryKpis: ({})
    property var historicalKpis: []
    property var latestLiveKpis: ({})
    property bool loading: false

    header: NymeaHeader {
        id: nymeaHeader
        text: qsTr("KPI Monitoring")
        backButtonVisible: true
        onBackPressed: pageStack.pop()
    }

    Connections {
        target: root.hemsManager
        onLiveKPIsReceived: {
            root.latestLiveKpis = liveKpis
            if (root.currentShortcut === "today") {
                root.aggregateData()
            }
            root.loading = false
        }
        onLiveKPIsChanged: {
            root.latestLiveKpis = liveKpis
            if (root.currentShortcut === "today") {
                root.aggregateData()
            }
        }
        onKpisReceived: {
            root.historicalKpis = kpis
            root.aggregateData()
            root.loading = false
        }
        onIntervalCompleted: {
            root.refreshData()
        }
    }

    function aggregateData() {
        // Preference: If Today is selected and we have Live KPIs, use them as they are the plugin's most current truth
        if (root.currentShortcut === "today" && Object.keys(root.latestLiveKpis).length > 0) {
            root.summaryKpis = root.latestLiveKpis
            return
        }

        if (root.historicalKpis.length === 0) {
            root.summaryKpis = {}
            return
        }

        var summary = {
            gridImportWh: 0,
            gridExportWh: 0,
            ownGenerationWh: 0,
            totalConsumptionWh: 0,
            selfConsumptionWh: 0,
            evChargingWh: 0,
            evSolarWh: 0,
            batteryChargeWh: 0,
            batteryDischargeWh: 0,
            heatPumpWh: 0,
            gridCostEuro: 0,
            ownGenerationCostEuro: 0,
            realCostEuro: 0,
            emsSavingsEuro: 0,
            exportRevenueEuro: 0,
            co2GridG: 0,
            co2OwnG: 0,
            co2TotalG: 0,
            co2SavingsG: 0,
            maxGridImportW: 0,
            maxGridExportW: 0,
            maxProductionW: 0,
            maxConsumptionW: 0,
            maxEvPowerW: 0,
            autarkyRate: 0,
            selfConsumptionRate: 0,
            averagePriceEuroKwh: 0,
            hpInterventionCount: 0,
            hpInterventionRate: 0,
            evLowPriceWh: 0,
            evLowPriceRate: 0
        }

        for (var i = 0; i < root.historicalKpis.length; i++) {
            var entry = root.historicalKpis[i]
            summary.gridImportWh += entry.gridImportWh || 0
            summary.gridExportWh += entry.gridExportWh || 0
            summary.ownGenerationWh += entry.ownGenerationWh || 0
            summary.totalConsumptionWh += entry.totalConsumptionWh || 0
            summary.selfConsumptionWh += entry.selfConsumptionWh || 0
            summary.evChargingWh += entry.evChargingWh || 0
            summary.evSolarWh += entry.evSolarWh || 0
            summary.batteryChargeWh += entry.batteryChargeWh || 0
            summary.batteryDischargeWh += entry.batteryDischargeWh || 0
            summary.heatPumpWh += entry.heatPumpWh || 0
            
            summary.gridCostEuro += entry.gridCostEuro || 0
            summary.ownGenerationCostEuro += entry.ownGenerationCostEuro || 0
            summary.realCostEuro += entry.realCostEuro || 0
            summary.emsSavingsEuro += entry.emsSavingsEuro || 0
            summary.exportRevenueEuro += entry.exportRevenueEuro || 0
            
            summary.co2GridG += entry.co2GridG || 0
            summary.co2OwnG += entry.co2OwnG || 0
            summary.co2TotalG += entry.co2TotalG || 0
            summary.co2SavingsG += entry.co2SavingsG || 0
            
            summary.maxGridImportW = Math.max(summary.maxGridImportW, entry.maxGridImportW || 0)
            summary.maxGridExportW = Math.max(summary.maxGridExportW, entry.maxGridExportW || 0)
            summary.maxProductionW = Math.max(summary.maxProductionW, entry.maxProductionW || 0)
            summary.maxConsumptionW = Math.max(summary.maxConsumptionW, entry.maxConsumptionW || 0)
            summary.maxEvPowerW = Math.max(summary.maxEvPowerW, entry.maxEvPowerW || 0)
            
            // New KPIs: Heat Pump Intervention & EV Low-Price
            summary.hpInterventionCount += entry.hpInterventionCount || 0
            summary.evLowPriceWh += entry.evLowPriceWh || 0
        }

        // Recalculate rates for the whole period
        if (summary.totalConsumptionWh > 0) {
            summary.autarkyRate = summary.selfConsumptionWh / summary.totalConsumptionWh
            summary.averagePriceEuroKwh = summary.realCostEuro / (summary.totalConsumptionWh / 1000.0)
        }
        if (summary.ownGenerationWh > 0) {
            summary.selfConsumptionRate = summary.selfConsumptionWh / summary.ownGenerationWh
        }
        
        // Calculate new KPI rates
        // Heat Pump Intervention Rate: Use the rate from the last entry or calculate based on count
        if (root.historicalKpis.length > 0) {
            var lastEntry = root.historicalKpis[root.historicalKpis.length - 1]
            summary.hpInterventionRate = lastEntry.hpInterventionRate || 0
        }
        
        // EV Low-Price Rate: Recalculate based on total evLowPriceWh / evChargingWh
        if (summary.evChargingWh > 0) {
            summary.evLowPriceRate = summary.evLowPriceWh / summary.evChargingWh
        }

        root.summaryKpis = summary
    }

    function refreshData() {
        if (!root.hemsManager) return
        
        root.loading = true
        root.summaryKpis = ({})
        root.historicalKpis = []
        
        var start = new Date()
        var end = new Date()
        var resolution = "15min" 

        if (root.currentShortcut === "today") {
            root.hemsManager.getLiveKPIs()
            // Backend segments for Today (fallback/sync)
            start.setHours(0, 0, 0, 0)
        } else if (root.currentShortcut === "yesterday") {
            start.setDate(start.getDate() - 1)
            start.setHours(0, 0, 0, 0)
            end = new Date(start)
            end.setHours(23, 59, 59, 999)
        } else if (root.currentShortcut === "week") {
            var day = start.getDay() || 7
            start.setDate(start.getDate() - (day - 1))
            start.setHours(0, 0, 0, 0)
        } else if (root.currentShortcut === "month") {
            start.setDate(1)
            start.setHours(0, 0, 0, 0)
        } else if (root.currentShortcut === "selection") {
            start = new Date(root.customStartDate)
            start.setHours(0, 0, 0, 0)
            end = new Date(root.customEndDate)
            end.setHours(23, 59, 59, 999)
        }
        
        // Use local ISO format without timezone offset to match backend's device-local expectation
        var startStr = Qt.formatDateTime(start, "yyyy-MM-ddTHH:mm:ss")
        var endStr = Qt.formatDateTime(end, "yyyy-MM-ddTHH:mm:ss")
        root.hemsManager.getKPIs(resolution, startStr, endStr)
    }

    Component.onCompleted: refreshData()

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        opacity: root.loading ? 0.5 : 1.0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 20
            Layout.topMargin: 10
            Layout.bottomMargin: 20

            ConsolinnoSelectionTabs {
                id: selectionTabs
                Layout.fillWidth: true
                Layout.margins: 10
                model: [
                    qsTr("Today"),
                    qsTr("Yesterday"),
                    qsTr("This Week"),
                    qsTr("This Month"),
                    qsTr("Selection")
                ]
                currentIndex: 0
                property var values: ["today", "yesterday", "week", "month", "selection"]
                onTabSelected: {
                    root.currentShortcut = values[index]
                    root.refreshData()
                }
            }

            // --- CUSTOM SELECTION CONTROLS ---
            RowLayout {
                visible: root.currentShortcut === "selection"
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10
                
                ColumnLayout {
                    Label { text: qsTr("Start Date"); font.pixelSize: 12; color: Style.subTextColor }
                    ConsolinnoTextField {
                        id: startField
                        placeholderText: "YYYY-MM-DD"
                        text: Qt.formatDate(root.customStartDate, "yyyy-MM-dd")
                        onEditingFinished: {
                            var cleaned = text.split("-").map(function(p, i) {
                                if (i > 0 && p.length === 1) return "0" + p
                                return p
                            }).join("-")
                            var d = Date.fromLocaleDateString(Qt.locale(), cleaned, "yyyy-MM-dd")
                            if (!isNaN(d.getTime())) {
                                root.customStartDate = d
                                root.refreshData()
                            }
                        }
                    }
                }
                ColumnLayout {
                    Label { text: qsTr("End Date"); font.pixelSize: 12; color: Style.subTextColor }
                    ConsolinnoTextField {
                        id: endField
                        placeholderText: "YYYY-MM-DD"
                        text: Qt.formatDate(root.customEndDate, "yyyy-MM-dd")
                        onEditingFinished: {
                            var cleaned = text.split("-").map(function(p, i) {
                                if (i > 0 && p.length === 1) return "0" + p
                                return p
                            }).join("-")
                            var d = Date.fromLocaleDateString(Qt.locale(), cleaned, "yyyy-MM-dd")
                            if (!isNaN(d.getTime())) {
                                d.setHours(23, 59, 59, 999)
                                root.customEndDate = d
                                root.refreshData()
                            }
                        }
                    }
                }
            }

            // --- SECTOR REPEATER ---
            Repeater {
                model: [
                    {
                        title: qsTr("Energy (kWh)"),
                        kpis: [
                            { label: qsTr("Grid Import"), value: (root.summaryKpis.gridImportWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Grid Export"), value: (root.summaryKpis.gridExportWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Generation"), value: (root.summaryKpis.ownGenerationWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Consumption"), value: (root.summaryKpis.totalConsumptionWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Self-consumption"), value: (root.summaryKpis.selfConsumptionWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("EV Charging"), value: (root.summaryKpis.evChargingWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Solar EV Share"), value: (root.summaryKpis.evSolarWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Battery Charge"), value: (root.summaryKpis.batteryChargeWh / 1000 || 0).toFixed(2) },
                            { label: qsTr("Battery Discharge"), value: (root.summaryKpis.batteryDischargeWh / 1000 || 0).toFixed(2) }
                        ]
                    },
                    {
                        title: qsTr("Power Peaks (kW)"),
                        kpis: [
                            { label: qsTr("Pmax Import"), value: (root.summaryKpis.maxGridImportW / 1000 || 0).toFixed(2) },
                            { label: qsTr("Pmax Export"), value: (root.summaryKpis.maxGridExportW / 1000 || 0).toFixed(2) },
                            { label: qsTr("Pmax Gen"), value: (root.summaryKpis.maxProductionW / 1000 || 0).toFixed(2) },
                            { label: qsTr("Pmax Cons"), value: (root.summaryKpis.maxConsumptionW / 1000 || 0).toFixed(2) },
                            { label: qsTr("Pmax E-Mobility"), value: (root.summaryKpis.maxEvPowerW / 1000 || 0).toFixed(2) }
                        ]
                    },
                    {
                        title: qsTr("Economics (€)"),
                        kpis: [
                            { label: qsTr("Grid Cost"), value: (root.summaryKpis.gridCostEuro || 0).toFixed(2) },
                            { label: qsTr("Own Gen. Cost"), value: (root.summaryKpis.ownGenerationCostEuro || 0).toFixed(2) },
                            { label: qsTr("Real Cost"), value: (root.summaryKpis.realCostEuro || 0).toFixed(2) },
                            { label: qsTr("EMS Savings"), value: (root.summaryKpis.emsSavingsEuro || 0).toFixed(2) },
                            { label: qsTr("Avg Price"), value: (root.summaryKpis.averagePriceEuroKwh || 0).toFixed(2), unit: "/kWh" }
                        ]
                    },
                    {
                        title: qsTr("Sustainability (kg CO2)"),
                        kpis: [
                            { label: qsTr("Grid Emission"), value: (root.summaryKpis.co2GridG / 1000 || 0).toFixed(2) },
                            { label: qsTr("Own Gen (CO2)"), value: (root.summaryKpis.co2OwnG / 1000 || 0).toFixed(2) },
                            { label: qsTr("Total (CO2)"), value: (root.summaryKpis.co2TotalG / 1000 || 0).toFixed(2) },
                            { label: qsTr("CO2 Savings"), value: (root.summaryKpis.co2SavingsG / 1000 || 0).toFixed(2) }
                        ]
                    },
                    {
                        title: qsTr("Efficiency (%)"),
                        kpis: [
                            { label: qsTr("Autarky Degree"), value: ((root.summaryKpis.autarkyRate || 0) * 100).toFixed(1) },
                            { label: qsTr("Self-cons. Rate"), value: ((root.summaryKpis.selfConsumptionRate || 0) * 100).toFixed(1) }
                        ]
                    },
                    {
                        title: qsTr("HEMS Optimization"),
                        kpis: [
                            { label: qsTr("HP Intervention Rate"), value: ((root.summaryKpis.hpInterventionRate || 0) * 100).toFixed(1), unit: "%" },
                            { label: qsTr("HP Interventions"), value: (root.summaryKpis.hpInterventionCount || 0).toString() },
                            { label: qsTr("EV Low-Price Rate"), value: ((root.summaryKpis.evLowPriceRate || 0) * 100).toFixed(1), unit: "%" },
                            { label: qsTr("EV Low-Price Energy"), value: (root.summaryKpis.evLowPriceWh / 1000 || 0).toFixed(2), unit: " kWh" }
                        ]
                    }
                ]
                delegate: ColumnLayout {
                    spacing: 10
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20

                    Label {
                        text: modelData.title
                        font.pixelSize: 18
                        font.bold: true
                        color: Style.consolinnoDark
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10
                        Repeater {
                            model: modelData.kpis
                            delegate: Rectangle {
                                width: (contentColumn.width - 50) / 2
                                height: 75
                                color: Style.backgroundColor
                                radius: 8
                                border.color: Style.consolinnoLight
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        font.pixelSize: 10
                                        color: Style.subTextColor
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.value + (modelData.unit || "")
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: Style.consolinnoDark
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.loading
        visible: running
        z: 100
    }
}

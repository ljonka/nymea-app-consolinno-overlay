import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.2
import QtCharts 2.3
import Nymea 1.0
import "qrc:/ui/components/"

Page {
    id: root
    property HemsManager hemsManager
    property string currentResolution: "now"
    property var liveKpis: ({})
    property var historicalKpis: []
    property bool loading: false

    header: NymeaHeader {
        id: nymeaHeader
        text: qsTr("KPI Overview")
        backButtonVisible: true
        onBackPressed: pageStack.pop()
    }

    Connections {
        target: root.hemsManager
        onLiveKPIsReceived: {
            root.liveKpis = liveKpis
            root.loading = false
        }
        onLiveKPIsChanged: {
            if (root.currentResolution === "now") {
                root.liveKpis = liveKpis
            }
        }
        onKpisReceived: {
            root.historicalKpis = kpis
            root.loading = false
            root.updateCharts()
        }
        onIntervalCompleted: {
            if (root.currentResolution !== "now") {
                root.refreshData()
            }
        }
    }

    function refreshData() {
        if (!root.hemsManager) return
        
        root.loading = true
        if (root.currentResolution === "now") {
            root.hemsManager.getLiveKPIs()
        } else {
            var end = new Date()
            var start = new Date()
            
            if (root.currentResolution === "15m") start.setHours(start.getHours() - 1)
            else if (root.currentResolution === "1h") start.setHours(start.getHours() - 6)
            else if (root.currentResolution === "day") start.setDate(start.getDate() - 1)
            else if (root.currentResolution === "week") start.setDate(start.getDate() - 7)
            else if (root.currentResolution === "month") start.setMonth(start.getMonth() - 1)
            else if (root.currentResolution === "year") start.setFullYear(start.getFullYear() - 1)
            
            root.hemsManager.getKPIs(root.currentResolution, start.toISOString(), end.toISOString())
        }
    }

    function updateCharts() {
        energyBarSet.values = []
        productionBarSet.values = []
        historicalAxisX.categories = []
        historicalFinancialAxisX.categories = []

        for (var i = 0; i < root.historicalKpis.length; i++) {
            var entry = root.historicalKpis[i]
            energyBarSet.append(entry.gridImportWh || 0)
            productionBarSet.append(entry.pvProductionWh || 0)
            var timeStr = Qt.formatDateTime(new Date(entry.timestamp), "HH:mm")
            historicalAxisX.append(timeStr)
            historicalFinancialAxisX.append(timeStr)
        }
    }

    Component.onCompleted: refreshData()

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 20

            ConsolinnoSelectionTabs {
                id: selectionTabs
                Layout.fillWidth: true
                Layout.margins: 10
                model: [
                    qsTr("Now"),
                    qsTr("15m"),
                    qsTr("1h"),
                    qsTr("Day"),
                    qsTr("Week"),
                    qsTr("Month"),
                    qsTr("Year")
                ]
                property var values: ["now", "15m", "1h", "day", "week", "month", "year"]
                onTabSelected: {
                    root.currentResolution = values[index]
                    root.refreshData()
                }
            }

            // --- NOW VIEW (Cards) ---
            ColumnLayout {
                visible: root.currentResolution === "now"
                Layout.fillWidth: true
                spacing: 15

                Label {
                    text: qsTr("Live KPIs")
                    font.pixelSize: 20
                    font.bold: true
                    color: Style.consolinnoDark
                    Layout.alignment: Qt.AlignHCenter
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    spacing: 10
                    
                    Repeater {
                        model: [
                            { label: qsTr("Grid Import"), value: (root.liveKpis.gridImportWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Grid Export"), value: (root.liveKpis.gridExportWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("PV Production"), value: (root.liveKpis.pvProductionWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Own Gen."), value: (root.liveKpis.ownGenerationWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Self-Cons."), value: (root.liveKpis.selfConsumptionRate || 0).toFixed(1), unit: "%" },
                            { label: qsTr("Autarky"), value: (root.liveKpis.autarkyRate || 0).toFixed(1), unit: "%" },
                            { label: qsTr("Heat Pump"), value: (root.liveKpis.heatPumpWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("EV Charging"), value: (root.liveKpis.evChargingWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Bat. Charge"), value: (root.liveKpis.batteryChargeWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Bat. Disch."), value: (root.liveKpis.batteryDischargeWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Max Power"), value: (root.liveKpis.maxPowerW || 0).toFixed(0), unit: "W" },
                            { label: qsTr("Min Power"), value: (root.liveKpis.minPowerW || 0).toFixed(0), unit: "W" },
                            { label: qsTr("Max Import"), value: (root.liveKpis.maxGridImportW || 0).toFixed(0), unit: "W" },
                            { label: qsTr("Max Export"), value: (root.liveKpis.maxGridExportW || 0).toFixed(0), unit: "W" },
                            { label: qsTr("Wind Prod."), value: (root.liveKpis.windProductionWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("CHP Prod."), value: (root.liveKpis.chpProductionWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Direct Cons."), value: (root.liveKpis.pvDirectConsumptionWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("EV Solar"), value: (root.liveKpis.evSolarWh || 0).toFixed(1), unit: "Wh" },
                            { label: qsTr("Avg Price"), value: (root.liveKpis.averagePrice || 0).toFixed(3), unit: "€" },
                            { label: qsTr("Grid Cost"), value: (root.liveKpis.gridCost || 0).toFixed(2), unit: "€" },
                            { label: qsTr("Revenue"), value: (root.liveKpis.exportRevenue || 0).toFixed(2), unit: "€" },
                            { label: qsTr("Savings"), value: (root.liveKpis.pvSavings || 0).toFixed(2), unit: "€" },
                            { label: qsTr("LCOE Cost"), value: (root.liveKpis.lcoeCost || 0).toFixed(2), unit: "€" }
                        ]
                        
                        delegate: Rectangle {
                            width: (contentColumn.width - 30) / 2
                            height: 80
                            color: Style.backgroundColor
                            radius: 8
                            border.color: Style.consolinnoLight
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 20
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
                                    text: modelData.value + " " + modelData.unit
                                    font.pixelSize: 16
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

            // --- HISTORY VIEW (Charts) ---
            ColumnLayout {
                visible: root.currentResolution !== "now"
                Layout.fillWidth: true
                spacing: 15

                Label {
                    text: qsTr("Historical Trends")
                    font.pixelSize: 20
                    font.bold: true
                    color: Style.consolinnoDark
                    Layout.alignment: Qt.AlignHCenter
                }

                ChartView {
                    id: historyChart
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom
                    legend.labelColor: Style.foregroundColor
                    backgroundColor: "transparent"

                    BarSeries {
                        id: energyBarSeries
                        axisX: BarCategoryAxis { id: historicalAxisX }
                        BarSet { id: energyBarSet; label: qsTr("Grid Import (Wh)") }
                        BarSet { id: productionBarSet; label: qsTr("PV production (Wh)") }
                    }
                }
                
                // second chart for financial data
                ChartView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom
                    legend.labelColor: Style.foregroundColor
                    backgroundColor: "transparent"
                    
                    BarSeries {
                        axisX: BarCategoryAxis { id: historicalFinancialAxisX }
                        BarSet { 
                            label: qsTr("Grid Cost (€)")
                            values: {
                                var v = []
                                for(var i=0; i<root.historicalKpis.length; i++) v.push(root.historicalKpis[i].gridCost || 0)
                                return v
                            }
                        }
                        BarSet { 
                            label: qsTr("Revenue (€)")
                            values: {
                                var v = []
                                for(var i=0; i<root.historicalKpis.length; i++) v.push(root.historicalKpis[i].exportRevenue || 0)
                                return v
                            }
                        }
                    }
                }
            }

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: root.loading
            }
        }
    }
}

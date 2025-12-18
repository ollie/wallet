class HighchartsConfig {
  static #initialized

  static init() {
    if (this.#initialized) {
      return
    }

    Highcharts.setOptions({
      credits: {
        enabled: false
      },
      lang: {
        contextButtonTitle: 'Kontextové menu',
        decimalPoint: ',',
        downloadCSV: 'Stáhnout CSV',
        downloadJPEG: 'Stáhnout JPEG',
        downloadPDF: 'Stáhnout PDF',
        downloadPNG: 'Stáhnout PNG',
        downloadSVG: 'Stáhnout SVG',
        downloadXLS: 'Stáhnout XLS',
        invalidDate: undefined,
        loading: 'Načítám…',
        months: ['Leden', 'Únor', 'Březen', 'Duben', 'Květen', 'Červen', 'Červenec', 'Srpen', 'Září', 'Říjen', 'Listopad', 'Prosinec'],
        noData: 'Žádná data k zobrazení',
        numericSymbolMagnitude: 1000,
        numericSymbols: ['k', 'M', 'G', 'T', 'P', 'E'],
        openInCloud: 'Otevřít v Highcharts Cloud',
        printChart: 'Tisknout',
        rangeSelectorFrom: 'Od',
        rangeSelectorTo: 'Do',
        rangeSelectorZoom: 'Zoom',
        resetZoom: 'Vyresetovat zoom',
        resetZoomTitle: 'Vyresetovat zoom na 1:1',
        shortMonths: ['Led', 'Úno', 'Bře', 'Dub', 'Kvě', 'Čvn', 'Čvc', 'Spr', 'Zář', 'Říj', 'Lis', 'Pro'],
        shortWeekdays: undefined,
        thousandsSep: ' ',
        weekdays: ['Neděle', 'Pondělí', 'Úterý', 'Středa', 'Čtvrtek', 'Pátek', 'Sobota']
      }
    })

    this.#initialized = true
  }
}

window.HighchartsConfig = HighchartsConfig

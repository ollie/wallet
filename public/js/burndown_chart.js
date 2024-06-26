// Generated by CoffeeScript 2.7.0
(function() {
  this.BurndownChart = class BurndownChart {
    constructor() {
      this.element = $('#burndown-chart');
      if (!this.element.length) {
        return;
      }
      HighchartsConfig.init();
      this.init();
    }

    init() {
      return $.getJSON(this.element.data('url'), (data) => {
        var balance, balanceWithUnaccounted, date, i, item, len, monthName, options, plotLines, series, targetBalance, timestamp;
        if (!data.length) {
          return;
        }
        series = {
          actual: {
            name: 'Celkem',
            showInNavigator: true,
            color: '#7cb5ec',
            lineWidth: 4,
            type: 'line',
            index: 3,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: '#7cb5ec',
              fillColor: 'white'
            },
            data: []
          },
          unaccounted: {
            name: 'Nezaúčtované',
            showInNavigator: false,
            color: '#f1c40f',
            lineWidth: 4,
            type: 'line',
            index: 2,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: '#f1c40f',
              fillColor: 'white'
            },
            data: []
          },
          target: {
            name: 'Cíl',
            showInNavigator: false,
            color: '#dddddd',
            lineWidth: 4,
            type: 'line',
            index: 1,
            marker: {
              lineWidth: 4,
              radius: 6,
              lineColor: '#dddddd',
              fillColor: 'white'
            },
            data: []
          }
        };
        plotLines = [];
        for (i = 0, len = data.length; i < len; i++) {
          item = data[i];
          date = new Date(item.date);
          timestamp = date.getTime();
          balance = null;
          if (item.balance !== null) {
            balance = Number(item.balance);
          }
          targetBalance = null;
          if (item.target_balance !== null) {
            targetBalance = Number(item.target_balance);
          }
          balanceWithUnaccounted = null;
          if (item.balance_with_unaccounted !== null) {
            balanceWithUnaccounted = Number(item.balance_with_unaccounted);
          }
          if (date.getDate() === 1) {
            monthName = Highcharts.getOptions().lang.months[date.getMonth()];
            plotLines.push(this._createPlotLine(timestamp, monthName));
          }
          series.actual.data.push([timestamp, balance]);
          if (balanceWithUnaccounted !== null) {
            series.unaccounted.data.push([timestamp, balanceWithUnaccounted]);
          }
          series.target.data.push([timestamp, targetBalance]);
        }
        options = {
          chart: {
            height: 500,
            spacing: [5, 0, 5, 0]
          },
          type: 'line',
          xAxis: {
            plotLines: plotLines
          },
          series: [series.actual, series.unaccounted, series.target],
          // plotOptions:
          //   series:
          //     animation: 500
          rangeSelector: {
            buttons: [
              {
                type: 'week',
                count: 1,
                text: 'Týden'
              },
              {
                type: 'all',
                text: 'Vše'
              }
            ],
            selected: 1,
            inputBoxWidth: 100,
            inputDateFormat: '%B %Y',
            inputEditDateFormat: '%d. %m. %Y'
          },
          credits: {
            enabled: false
          }
        };
        return Highcharts.stockChart(this.element.attr('id'), options);
      });
    }

    _createPlotLine(value, text) {
      return {
        color: '#e6e6e6',
        value: value,
        width: 1,
        label: {
          text: text,
          style: {
            color: '#cccccc'
          }
        }
      };
    }

  };

}).call(this);

// Generated by CoffeeScript 2.7.0
(function() {
  this.TagSelect = class TagSelect {
    constructor() {
      this._handleChange = this._handleChange.bind(this);
      this._handleTagRemove = this._handleTagRemove.bind(this);
      this.select = $('.js-tags-select');
      this.searchInput = $('.js-tags-search-input');
      this.datalist = $('.js-tags-datalist');
      this.tagsList = $('.js-tags-list');
      this.template = $('.js-tags-select-template');
      this.searchInput.on('change', this._handleChange);
      this.tagsList.on('click', '.js-tag-remove', this._handleTagRemove);
    }

    _handleChange(e) {
      var $option, html, id, tagName;
      tagName = this.searchInput.val();
      if (!tagName) {
        return;
      }
      $option = this.datalist.find(`option[value=\"${tagName}\"]`);
      id = $option.data('id');
      if (!id) {
        return;
      }
      $option = this.select.find(`option[value=\"${id}\"]`);
      if (!$option) {
        return;
      }
      $option.attr('selected', true);
      html = this.template.html();
      html = html.replace('#name#', tagName);
      html = html.replace('#id#', id);
      this.tagsList.append(html);
      return this.searchInput.val('');
    }

    _handleTagRemove(e) {
      var $button, $listItem, $option, id;
      $button = $(e.currentTarget);
      $listItem = $button.parents('.js-tag-list-item');
      id = $button.data('id');
      $option = this.select.find(`option[value=\"${id}\"]`);
      $option.attr('selected', false);
      return $listItem.remove();
    }

  };

}).call(this);

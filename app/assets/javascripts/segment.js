$(document).ready(function(e){

  var editFieldClass = '.edit-field', editableTextField = '.editable-field-icon';
  var editableFieldText = '.editable-field-text', updateFieldClass = '.update-field';
  var updateField = getOnlyText(updateFieldClass)
  var editField = getOnlyText(editFieldClass)

  $(document).on('click', editFieldClass, function(e){
    hidePreviousField();
    editItem = new EditItem(this, editableTextField);
    editItem.showEditTextBox();
    editItem.showTextInTextBox(editableFieldText);
    editItem.replaceIconWithSave('');
    $(this).removeClass(editField)
  });

  $( '.cancel-edit' ).click(function(){
    editItem = new EditItem(this, editableTextField);
    editItem.replaceIconWithSave('');
    editItem.removeTextBox('.text-field');
  });

  $(document).on('click', updateFieldClass, function(e){
    var inputField = $(this).parent().find('.text-field.segment-name')
    var isValidate = validateElement(inputField)
    if (isValidate)
      updateItem(inputField);
  });

  function EditItem(clickedElement, editableFieldsDiv){
    this.clickedElement = clickedElement, this.editableDiv = $( clickedElement ).parent(),
    this.editableFieldsDiv = editableFieldsDiv, this.replaceIconWithSave = replaceIconWithSave;
    this.showEditTextBox = showEditTextBox, this.showTextInTextBox = showTextInTextBox;
    this.removeTextBox = removeTextBox, this.getIcon = getIcon;
    this.toggleValue = 160;
    this.hidePreviousField = hidePreviousField;
  }

  function hidePreviousField(){
    element = $(editableTextField + ':visible').find('a.save-editable-field')
    element.length > 0 && element.click();
  }

  function showEditTextBox(){
    var textBox = this.editableDiv.find( this.editableFieldsDiv );
    textBox.fadeIn(this.toggleValue);
    var inputBox = textBox.find('.text-field')
    inputBox.val(this.editableDiv.find( editableFieldText ).text());
  }

  function showTextInTextBox(fieldText){
    this.editableDiv.find( fieldText ).hide(this.toggleValue);
  }

  function replaceIconWithSave(html){
    var icon = this.getIcon()
    icon.html(html);
    icon.addClass(updateField);
    icon.removeClass(editField);
  }

  function getIcon(){
    var editFieldELement = $(updateFieldClass).length > 0 ? updateFieldClass : editFieldClass
    var editIcon = this.editableDiv.find( editFieldELement );
    var saveIcon = this.editableDiv.parent().find( editFieldELement );
    return $(this.clickedElement).attr('class').match(/cancel-edit/g) ? saveIcon : editIcon
  }

  function getOnlyText(element){
    return element.replace('.', '')
  }

  function removeTextBox(textField){
    this.getIcon().addClass(editField);
    this.getIcon().removeClass(updateField);
    var element = this.clickedElement;
    $(element).parent().hide();
    $(element).parent().parent().find(editableFieldText).show();
    $(element).parent().find('.editable').attr('style', '')
  }

  function validateElement(element){
    if (element.val() == ''){
      element.attr('style', 'border: red solid 1px;')
      return false
    }
    else{
      element.attr('style', '')
      return true
    }
  }

  function updateItem(element){
    var textField = element.data('segment-id')
    $.ajax({
            method: 'patch', url: '/v1/lists/' + textField,
            dataType: 'json', data: { 'name': element.val() }

          }).done(function(msg){

            var flash_key = Object.keys(msg)[1];
            msg.status == 200 && $('#segment-' + element.data('segment-id')).text(msg.name);
            FlashHandler.setFlashMessage( msg[flash_key], flash_key );

          }).fail(function(msg){
            FlashHandler.setFlashMessage( 'Sorry semgent cannot updated', 'error' );
          });
  }

});

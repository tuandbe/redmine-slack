$(document).ready(function() {
  var isRecurringCheckbox = $('.is-recurring-checkbox');
  var recurringOptions = $('#recurring-options');
  var recurringTypeSelect = $('#recurring_type_select');
  var customDaysOptions = $('#custom-days-options');
  var hiddenCustomDays = $('#hidden_custom_days');
  var customDayCheckboxes = $('.custom-day-checkbox');

  function toggleRecurringOptions() {
    if (isRecurringCheckbox.is(':checked')) {
      recurringOptions.show();
    } else {
      recurringOptions.hide();
    }
  }

  function toggleCustomDaysOptions() {
    if (recurringTypeSelect.val() === 'custom') {
      customDaysOptions.show();
    } else {
      customDaysOptions.hide();
    }
  }

  function updateHiddenCustomDays() {
    var selectedDays = customDayCheckboxes.filter(':checked').map(function() {
      return $(this).val();
    }).get().join(',');
    hiddenCustomDays.val(selectedDays);
  }

  if (isRecurringCheckbox.length) {
    isRecurringCheckbox.on('change', toggleRecurringOptions);
  }

  if (recurringTypeSelect.length) {
    recurringTypeSelect.on('change', toggleCustomDaysOptions);
  }

  if (customDayCheckboxes.length) {
    customDayCheckboxes.on('change', updateHiddenCustomDays);
  }

  // Initial setup
  toggleRecurringOptions();
  toggleCustomDaysOptions();
  updateHiddenCustomDays();
}); 

# Description:
#   Calculates the number of working days between two dates.
#   Adapted from Ken Pespisa's script at http://partialclass.blogspot.com/2011/07/calculating-working-days-between-two.html
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   workingdays <start date>, <end date> (true|false)- calculate number of working days; date strings are expected to be an RFC2822 or ISO 8601 date
#
# Author:
#   ericjsilva

US_holidays = [
  "2014-11-27",
  "2014-12-25",
  "2014-12-26",
  "2015-01-01",
  "2015-01-19",
  "2015-02-16",
  "2015-05-25",
  "2015-07-03",
  "2015-09-07",
  "2015-11-26",
  "2015-11-27",
  "2015-12-24",
  "2015-12-25"
]

module.exports = (robot) ->
  robot.respond /(working\s?days|work\s?days|wd) (.*),\s?(.*) (.*)/i, (msg) ->
    try

      sDate = msg.match[2]
      # Determine if the true/false parameter was passed in
      omitHolidays = false
      if msg.match[3]
        eDate = msg.match[3]
        omitHolidays = true if msg.match[4] == "true"
      else
        eDate = msg.match[4]
        omitHolidays is false

      workingDaysBetweenDates msg, sDate, eDate, omitHolidays, (result) ->
        retMsg = "#{result}" + " days between " + sDate + " and " + eDate
        retMsg = retMsg + " excluding holidays" if omitHolidays == true
        msg.send retMsg
    catch error
      msg.send error.message || 'Could not compute.'

workingDaysBetweenDates = (msg, sDate, eDate, omitHolidays, cb) ->
  startDate = new Date(sDate)
  endDate = new Date(eDate)

  # Validate input
  return 0  if endDate < startDate

  # Calculate days between dates
  millisecondsPerDay = 86400 * 1000 # Day in milliseconds
  startDate.setHours(0, 0, 0, 1) # Start just after midnight
  endDate.setHours(23, 59, 59, 999) # End just before midnight
  diff = endDate - startDate # Milliseconds between datetime objects
  days = Math.ceil(diff / millisecondsPerDay)

  # Subtract two weekend days for every week in between
  weeks = Math.floor(days / 7)
  days = days - (weeks * 2)

  # Handle special cases
  startDay = startDate.getDay()
  endDay = endDate.getDay()

  # Remove weekend not previously removed.
  days = days - 2  if startDay - endDay > 1

  # Remove start day if span starts on Sunday but ends before Saturday
  days = days - 1  if startDay is 0 and endDay isnt 6

  # Remove end day if span ends on Saturday but starts after Sunday
  days = days - 1  if endDay is 6 and startDay isnt 0

  # Handle holidays
  if typeof omitHolidays is 'boolean' and omitHolidays is true
    for holiday in US_holidays
      hDate = new Date(holiday)
      hDate.setDate(hDate.getDate() + 1)
      days = days - 1 if hDate >= startDate and hDate <= endDate and hDate.getDay() isnt 0 and hDate.getDay() isnt 6

  cb "#{days}"
require 'date'

class Ride
  attr_accessor :from, :to, :date, :free_seats
  def initialize(from, to, date, free_seats)
    # Validation and conversion of integers and dates
    begin
      @from = from.downcase.capitalize()
      @to = to.downcase.capitalize()
      raise "date is not a Date" unless date.class == Date
      @date = date 
      raise "free seats is not an integer" unless free_seats.class == Integer
      @free_seats = free_seats
    rescue => exception
      puts exception
    end
  end
end

#* Creates a date object from a string formatted as DD-MM-YYYY
def create_date_object(date_str)
  # puts "creating date object"
  begin
    raise "Date is not in correct format" if date_str.split("-").length != 3
    date = Date.parse(date_str)
  rescue
    return nil
  end
  return date
end

#* validates that the incoming number is an actual number by trying to convert it to an integer
def validate_integer(number)
  begin
    return Integer(number)
  rescue
    return nil
  end
end

#* Creates a new ride object from input
def create_ride(rides, from, to, date, free_seats)
  begin
    raise "Invalid amount of input" if from.nil? || to.nil? || date.nil? || free_seats.nil?
    date = create_date_object(date)
    raise "date is invalid" if date.nil?
    free_seats = validate_integer(free_seats)
    raise "free seats is invalid" if free_seats.nil?
    raise "invalid amount of inputs" unless from && to && date && free_seats
    rides.push(Ride.new(from, to, date, free_seats))
  rescue => exception
    puts exception
  end
end

#* Creates a new ride based on the last ride in the list, with to and from switched, only takes a date
def create_return_ride(rides, date)
  # validate that there is a ride to create a return ride from
  begin 
    raise "There is no previous ride to create a return ride from" unless rides.length >= 1
    latest_ride = rides[-1]
    raise "Date is invalid" if create_date_object(date).nil?
    raise  "Return date must be after or on origial trips date" unless create_date_object(date) >= latest_ride.date 
      create_ride(rides, latest_ride.to, latest_ride.from, date, latest_ride.free_seats)
  rescue => e
    puts e
  end

end

#* Takes a query which is an array created from the input string, then matches each param with the list
def find_rides(rides, query)
  query.delete("S")
  result = []

  # we need to identify what params we are getting in, so we know what the rules for our search is.
  # To do this, we first declare the variables we know we can get so long as the input is proper
  from_location = nil
  to_location = nil
  from_date = nil
  to_date = nil
  min_free_seats = nil

  # Then we go through and convert integers and dates in our query, and based on success we can 
  # determine in whcih variable we need to store them
  query.each { |param| 
    begin
      if !validate_integer(param).nil?
        if min_free_seats == nil
          min_free_seats = validate_integer(param)
        else
          raise StandardError.new "Invalid amount of integers provided" 
        end
      elsif  !create_date_object(param).nil?
        if from_date == nil
          from_date = create_date_object(param)
        elsif to_date == nil
          to_date = create_date_object(param)
        else
          raise StandardError.new "Invalid amount of dates provided"
        end
      else
        if from_location == nil
          from_location = param.downcase.capitalize()
        elsif to_location == nil
          to_location = param.downcase.capitalize()
        else
          raise StandardError.new "Invalid amount of locations provided"
        end
      end
    rescue StandardError => e
      puts e
    end
  }

  # If only one date is provided at this point, we only have a range of one date
  to_date = from_date if to_date.nil?

  # for each ride, check
  rides.each do |ride|
    # 1. that the from_location matches origin
    next unless ride.from == from_location 
    # 2. that the to_location matches destination, iff there is one
    next unless ride.to == to_location if to_location != nil
    # 3. that the date is between from_date and to_date, if there is a date
    if from_date != nil
      next unless ride.date >= from_date && ride.date <= to_date
    end
    # 4. that the free seats is at least min_free_seats
    next unless ride.free_seats >= min_free_seats if min_free_seats != nil
    # If none of the above conditionals were met, we can push the current ride to results
    result.push(ride)
  end

  if result.length >= 1
    puts "Search completed with #{result.length} results"
    print_rides(result)
  else
    puts "No results"
  end
end

#* prints a list of rides
def print_rides(rides)
  for ride in rides
    puts "#{ride.from} #{ride.to} #{ride.date} #{ride.free_seats}"
  end
end


#* Creates seed data for debugging
def initialize_data(rides)
  locations = [
    'Copenhagen',
    'Århus',
    'Odense', 
    'Maribo', 
    'Nakskov', 
    'Vordingborg', 
    'Næstved', 
    'Ringsted'
  ]
  
  10.times {
    from = locations[rand(locations.length - 1)]
    to = nil
    # Make sure that origin and destination is not the same location
    while to == from || to.nil?
      to = locations[rand(locations.length - 1)]
    end

    date = "2022-1-#{rand(1..30)}"
    free_seats = rand(1..5)
    create_ride(rides, from, to, date, free_seats)
  }
end

##########################
# Beginning of execution #
##########################

puts "Welcome to the GoMoreOrLess ride sharing app"
puts "Program accepts the following commands:"
puts "L - List all rides"
puts "C (followed by 'origin destination date free-seats') - Create a new ride"
puts "R (followed by 'date') - Create a return ride for the last ride in the list"
puts "S (followed by parameters) - Search through the list"
puts "0 - exit application"

active = true
rides = []

# Comment this out to start the program without seeding data
initialize_data(rides)

while(active)
  # Get input from user and convert to array
  input = gets.chomp().split(" ")
  # make a switch statement to check if the command letter is valid, and run the given operation
  case input[0].upcase()
  when "L"
    print_rides(rides)
  when "C"
    create_ride(rides, input[1], input[2], input[3], input[4])
  when "R"
    create_return_ride(rides, input[1])
  when "S"
    find_rides(rides, input)
  when "0"
    active = false
    puts "Program terminated"
  else
    puts "Input is invalid, try again"
  end
end
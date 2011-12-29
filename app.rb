require './omegle'
require 'logger'

class Question
  attr_reader :text, :choices

  def initialize(text, choices = nil)
    @text = text
    @choices = choices
  end

  def ordered_choices
    letters = ('a'..'z').to_a
    choices.inject([]) do |acc, val|
      acc << "#{letters[acc.size]}) #{val}"
    end
  end
end

class AskOmegle
  attr_reader :logger

  def initialize(severity = Logger::INFO)
    @logger = Logger.new(STDOUT)
    @logger.level = severity
  end

  # Metodo principale, chiede e salva la domanda
  def ask(question)
    logger.debug "connecting to omegle"
    Omegle.start(:host => 'cardassia.omegle.com') do |omegle|

      omegle.typing
      logger.info question.text
      omegle.send question.text
      omegle.stopped_typing

      question.ordered_choices.each do |c|
        omegle.typing
        logger.info c
        omegle.send c
        omegle.stopped_typing
      end

      omegle.listen do |event|
        logger.debug event.inspect
        remote_messages = event.collect do |e|
          e if e.first == "gotMessage"
        end.compact.collect {|e| e.last}

        logger.debug remote_messages.inspect

        # qui va trappata la risposta, bisogna capire se ha risposto una delle lettere possibili,
        # in caso positivo ringraziare e chiudere la conversazione,
        # in caso negativo chiedere di rispondere solo con una delle alternative possibili
        # bisogna anche introdurre un timeout

        # input da tastiera da console: usato per il debug
        #message = gets.chomp
        # puts message

        # if message
        #   omegle.typing
        #   omegle.send message
        #   omegle.stopped_typing
        # end

        remote_messages = ''
        message = false

        return false if event.include? ["strangerDisconnected"]

      end
    end
  end
end

omegle = AskOmegle.new(Logger::DEBUG)

q = Question.new("I'm a bot, i was born today. I was programmed by a lazy guy that has an ugly job and wants me to do polls in his place, so the question is: which is the worst of 2011", ["justin bieber", "rebecca black", "the twilight movies"])
omegle.logger.debug "question initialized"
omegle.logger.debug "question text: #{q.text}"
q.ordered_choices.each {|c| omegle.logger.debug c}

begin
  result = omegle.ask(q)
end while result == false

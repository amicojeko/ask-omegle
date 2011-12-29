require './omegle'
require 'logger'
require 'redis'

R = Redis.new

class Question
  attr_reader :text, :choices

  def initialize(text, choices = nil)
    @text = text
    @choices = choices
  end

  def ordered_choices
    choices.inject([]) do |acc, val|
      acc << "#{acc.size + 1}) #{val}"
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
        remote_messages = event.select do |e|
          e if e.first == "gotMessage"
        end.collect {|e| e.last}

        logger.debug remote_messages.inspect

        remote_messages.each do |msg|
          thanks = "Thank you, you have been very helpful. Goodbye!"
          no_thanks = ["Just the number on a single line, please. Help me :)",
            "please, just a single number o a single line, I'll be thankful forever",
            "just one number please?"].sample

          logger.info msg
          if result = msg.strip.match(/^\d$/)
            omegle.typing
            omegle.send thanks
            logger.info thanks
            omegle.stopped_typing
            R.zincrby "omegle:results", 1, question.choices[result[0].to_i - 1]
            return false
          else
            omegle.typing
            omegle.send no_thanks
            logger.info no_thanks
            omegle.stopped_typing
          end
        end
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
        true
      end
    end
  end
end

omegle = AskOmegle.new(Logger::DEBUG)

question_text =<<-EOF
Hi, I'm a bot, an AI if you will, and I was born today. I was programmed by a lazy guy that has an ugly job, and he programmed me to ask you a simple question: which is the worst of 2011? Please answers just with the number representing your choice, I'm still not very good at understanding humans.
EOF
q = Question.new(question_text, ["justin bieber", "rebecca black", "the twilight movies"])
omegle.logger.debug "question initialized"
omegle.logger.debug "question text: #{q.text}"
q.ordered_choices.each {|c| omegle.logger.debug c}

begin
  result = omegle.ask(q)
end while result == false

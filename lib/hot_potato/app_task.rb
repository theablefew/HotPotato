require "socket"

module HotPotato
  
  # AppTasks are the controllers in the framework.  The Supervisor (See below) is responsible for
  # starting AppTasks.  There are three types: Faucets, Workers, and Sinks.
  module AppTask
   
   HEARTBEAT_INTERVAL   = 20
   HEARTBEAT_EXPIRE     = 30
   MESSAGE_COUNT_EXPIRE = 600
   
   include HotPotato::Core
   
   # Used to keep AppTask statistics when a message is received.
   def count_message_in
     m_in = stat.incr "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_in"
     stat.publish( "messages_in", {"hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_in".gsub('.','_') => m_in.to_s}.to_json )
     stat.expire "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_in", MESSAGE_COUNT_EXPIRE
   end
   
   # Used to keep AppTask statistics when a message is sent.
   def count_message_out
     m_out = stat.incr "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_out"     
     stat.publish( "messages_out", {"hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_out".gsub('.','_') => m_out.to_s}.to_json) 
     stat.expire "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_out", MESSAGE_COUNT_EXPIRE
   end
   
   # Starts the HeartBeat service to maintain the process id table.
   def start_heartbeat_service
     ati = AppTaskInfo.new(:classname => self.class.name)
     stat.set ati.key, ati.to_json, HEARTBEAT_EXPIRE

     Thread.new do
       log.info "Thread created for AppTask [Heartbeat]"
       loop do
         ati.touch
         stat.set ati.key, ati.to_json, HEARTBEAT_EXPIRE
         sleep HEARTBEAT_INTERVAL
       end
     end
   end
    
  end
  
end

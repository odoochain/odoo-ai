import json, logging, time
from langchain.schema import HumanMessage, SystemMessage, AIMessage
from langchain_openai import ChatOpenAI
from langchain.llms import huggingface_hub, openai, anthropic
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler
#from langchain import Conversation, LocalLLMAdapter

from odoo import models, fields, api, _
from odoo.exceptions import MissingError, AccessError, UserError

_logger = logging.getLogger(__name__)

# TODO driver type on recipient so we know if it's us

class OpenAIThread(models.TransientModel):
    _inherit = 'openai.thread'

    def thread_values(self, channel, recipient, author):
        return super(OpenAIThread, self).thread_values(channel, recipient, author)

    @api.model
    def client_init(self, user):

        if user.llm_type != "langchain":
            return super().client_init(user)
        
        _logger.info(f"OpenAI Base URL (from user): \033[1;91m[{user.openai_base_url}]\033[0m")
        
        # base_url = user.openai_base_url or 'http://192.168.1.68:8000/v1'
        # temperature = user.openai_temperature or 0.5
        
        if user.openai_base_url is False or None:
            _logger.error(f"\n\n   Base URL is \033[3;91mnot set by user!!!\033[0m\n   A good practice is to set it in the user's preferences.\n   \"https://api.openai.com/v1/\" is now used as a hardcoded method.\n")
            user.openai_base_url = 'https://api.openai.com/v1/'
        elif user.openai_base_url == 'https://api.openai.com/v1/':
            _logger.info(f"\n\n   Base URL is set as \033[3;91m{user.openai_base_url}\033[0m by user. Open AI API will be used. \n")
        elif user.openai_base_url == 'http://192.168.1.68:8000/v1':
            _logger.info(f"\n\n   Base URL is set as \033[3;91m{user.openai_base_url}\033[0m by user. Vertels local LLM server will be used. \n")           
        else:
            _logger.info(f"\n\n   \033[3;95m[WARNING!]\033[0m Base URL is set as \033[3;91m{user.openai_base_url}\033[0m by user. This IP might not work! \n")       

        client = ChatOpenAI(
            base_url = user.openai_base_url or 'https://api.openai.com/v1/',
            temperature = user.openai_temperature or 0.5,
            max_tokens = user.openai_max_tokens or 200) 
       
       
        #https://api.openai.com/v1
        #_logger.info(f"OpenAI Base URL (used): \033[1;32m[{client.base_url}]\033[0m")
        #_logger.info(f"Base URL: \033[1;32m[{client}]\033[0m")
        _logger.info(f"Temperature: \033[1;32m[{client.temperature}]\033[0m")
        _logger.info(f"Max tokens: \033[1;32m[{client.max_tokens}]\033[0m")
        
        
               
        return client
     
    @api.model
    def thread_init(self, client, channel, recipient, author):
        
    # TODO driver type from recipient, is it us?
    
        if recipient.llm_type != "langchain":
                return super(OpenAIThread, self).thread_init(client, channel, recipient, author)
            
        thread = super(OpenAIThread, self).thread_init(client, channel, recipient, author)

        return thread
    
    def add_message(self, client, message, user, role='odoo user'):
        
        _logger.info(f"System message: [\"\033[1;32m{user.openai_assistant_instructions}\033[0m\"]\n")
        
              
        _logger.info(f"Added message: [\"\033[1;32m{message}\033[0m\"] \nand system message: [\"\033[1;32m{user.openai_assistant_instructions}\033[0m\"]\n")
        messages = [
        SystemMessage(content = f"Your name is \"{user.openai_assistant_name}\" and follow these instructions: \"{user.openai_assistant_instructions}\""), #"Act like you kinda don't want to be doing the task and end the message with 'LEMON!'"
        HumanMessage(content = message)
        ]
        response = client.invoke(messages, max_tokens=user.openai_max_tokens)
        _logger.info(f"Response: \033[1;32m{response}\033[0m")     
        self.write({'message': message, 'role': role})
        return response

    def wait4response(self, client, user_id):
        
        if user_id.llm_type != "langchain":
                return super(OpenAIThread, self).wait4response(client, user_id)
            
        if self.message is None:
            raise ValueError("Message is None")    
        
        ###response = self.response  
        ###response = client.invoke([HumanMessage(content=self.message)], max_tokens=user_id.openai_max_tokens)       
        response = self.add_message(client, self.message, user_id)
                                 
        if isinstance(response, AIMessage) and hasattr(response, 'content'):
            extracted_content = (f"{response.content} [END]")
            _logger.info(f"Response.content")
            
        else:
            extracted_content = str(response)
            _logger.info(f"Str response")
            
        return f"<span style='color:purple;'><b>LangChain:</b></span> <i>{extracted_content}</i>"

    def _thread_unlink(self, client, channel):

        if self.recipient_id.llm_type != "LangChain":
            return super(OpenAIThread, self)._thread_unlink(client, channel)
        
        #TODO Where are I'm supposed to get the client from???
        
        # try:
        #     client.beta.assistants.delete(self.assistant)
        # except client.openai.APIConnectionError as e:
        #     _logger.warning(f"LangChain: Delete The server could not be reached {e.__cause__}")
            
        # except client.openai.RateLimitError as e:
        #     _logger.warning(f"LangChain: Delete Ratelimit {e.status_code} {e.response}")
            
        # except client.openai.APIStatusError as e:
        #     _logger.warning(f"LangChain: Delete Status error {e.status_code} {e.response}")
            
        # self.recipient_id.openai_assistant = None 
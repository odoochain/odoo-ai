# -*- coding: utf-8 -*-

import openai, uuid
import time
import yfinance as yf
import json
import logging
import requests as req

from odoo import models, fields, api, _
from odoo.exceptions import MissingError, AccessError, UserError

_logger = logging.getLogger(__name__)

# TODO driver type on recipient so we know if it's us
# TODO use litellm.utils.function_to_dict https://litellm.vercel.app/docs/completion/function_call#litellmfunction_to_dict---convert-functions-to-dictionary-for-openai-function-calling

class OpenAIThread(models.TransientModel):
    _inherit = 'openai.thread'


    def thread_values(self, channel, recipient, author):
        return super(OpenAIThread, self).thread_values(channel, recipient, author)


    @api.model
    def client_init(self, user):
        if user.llm_type != "openai":
            return super().client_init(user)
            #return super(OpenAIThread, self).client_init(user)
        
        try:
            _logger.info(f"[\033[1;36m OpenAI: client_init -> Init Api Key and Base URL. \033[0m")
            client = openai.OpenAI(api_key=user.openai_api_key,
                                   base_url=user.openai_base_url or 'https://api.openai.com/v1') #Alt: http://192.168.1.68:8000/v1
            return client
        
        except openai.APIConnectionError as e:
            _logger.error(f"OPENAI: The server could not be reached {e.__cause__}")
            self.log(f"{e.response}", user.partner_id, role='system')
            
        except openai.APIStatusError as e:
            self.log(f"OPENAI: Status error {e.status_code} {e.response}", user.partner_id, role='system')
            _logger.error(f"OPENAI: Status error {e.status_code} {e.response}")


    @api.model
    def thread_init(self, client, channel, recipient, author):
        # TODO driver type from recipient, is it us?
        if recipient.llm_type != "openai":
            return super(OpenAIThread, self).thread_init(client, channel, recipient, author)
        
        thread = super(OpenAIThread, self).thread_init(client, channel, recipient, author)
        _logger.info(f"\033[1;35m M:OpenAI bot / F:openai_thread / C:OpenAIThread / thread_init: Reading tools. \033[0m")
        tools_list = [{
            "type": "function",
            "function": {

                "name": "get_stock_price",
                "description": "Retrieve the latest closing price of a stock using its ticker symbol",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "symbol": {
                            "type": "string",
                            "description": "The ticker symbol of the stock"
                        }
                    },
                    "required": ["symbol"]
                }
            }
        }]

        # _logger.warning(f"Thread Init {client=} {recipient=}")
        if not recipient.openai_assistant:

            recipient.openai_assistant = thread.assistant = client.beta.assistants.create(
                name=recipient.openai_assistant_name or "Data Analyst Assistant",
                instructions=recipient.openai_assistant_instructions or "You are a personal Data Analyst Assistant",
                tools=tools_list,
                model=recipient.openai_assistant_model or 'gpt-4-1106-preview',
            ).id
        else:
            thread.assistant = recipient.openai_assistant
        client_thread = client.beta.threads.create()
        # _logger.error(f"{client_thread=}")
        # _logger.error(f"{client_thread.__dict__=}")
        thread.thread = client_thread.id
        # _logger.error(f"{thread.thread=}")
        return thread

    def log(self, message, author, role='user', status_code=200):
        self.env['openai.log'].create({'author_id': author.id,
                                       'channel_id': self.channel_id.id,
                                       'assistant': self.assistant,
                                       'thread': self.thread,
                                       'run': self.run,
                                       'message': message,
                                       'status_code': status_code,
                                       'role': role})

    def add_message(self, client, message, user_id, role='user'):
        """
            Add a Message to a Thread
        """
        if user_id.llm_type != "openai":
            return super(OpenAIThread, self).add_message(client, message, user_id, role)
        
        self.log(message, self.author_id, role=role)
        try:
            message = client.beta.threads.messages.create(
                thread_id=self.thread,
                role="user",
                content=message
            )
        except openai.APIConnectionError as e:
            _logger.warning(f"OPENAI: Thread The server could not be reached {e.__cause__}")
            self.log(f"OPENAI: Thread The server could not be reached {e.__cause__}", status_code=e.status_code,
                     role='openai')
            
        except openai.RateLimitError as e:
            _logger.warning(f"OPENAI: Thread Ratelimit {e.status_code} {e.response}")
            self.log(f"OPENAI: Thread Ratelimit {e.status_code} {e.response}", status_code=e.status_code, role='openai')
        except openai.APIStatusError as e:
            
            _logger.warning(f"OPENAI: Thread Status error {e.status_code} {e.response}")
            self.log(f"OPENAI: Thread Status error {e.status_code} {e.response}", status_code=e.status_code,
                     role='openai', )


    def wait4response(self, client, user_id):
        if user_id.llm_type != "openai":
            return super(OpenAIThread, self).wait4response(client, user_id)
        
        # TODO log does not save the correct author (it should be AI-bot)
        if self.run:
            _logger.warning(f"Run self run: {self.run=}")
            run_status = client.beta.threads.runs.retrieve(
                thread_id=self.thread,
                run_id=self.run
            )
            if run_status.status == 'expired':
                _logger.warning(f"OPENAI: Status error run expired {self.run=} {run_status.status=}")
                self.run = None
                self.log(f"OPENAI: Status error run expired {self.run=} {run_status.status=}",
                         self.recipient_id.parent_id, status_code=400, role='openai', )
        else:
            _logger.info(f"\033[1;35m M:OpenAI bot / F:openai_thread / C:OpenAIThread / wait4response: Run Saved. \033[0m")
            _logger.warning(f"Run saved {self.run=}")
            self.run = None

        _logger.warning(f"if not Run {self.run=} {self.thread=} {self.assistant=}")
        
        run_params = {
            'thread_id': self.thread,  # eller vilket värde du använder för thread_id
            'assistant_id': self.assistant,  # eller vilket värde du använder för assistant_id
        }
        
        if not self.run:
            try:
                _logger.warning(f"Creating run")
                _logger.info(f"Request to create run: {run_params}")
                run = client.beta.threads.runs.create(
                    thread_id=self.thread,
                    assistant_id=self.assistant,
                    #instructions=f"Please address the user as {self.author_id.name}."
                )
                _logger.warning(f"Run created {run.id=}")
                self.log(run.model_dump_json(indent=4), self.recipient_id.parent_id, role='run')
                _logger.warning(f"Model_dump: {run.model_dump_json(indent=4)} {run.id=}")
                self.run = run.id
            except openai.APIConnectionError as e:
                _logger.warning(f"OPENAI: Run The server could not be reached {e.__cause__}")
                self.log(f"OPENAI: Run The server could not be reached {e.__cause__}", self.recipient_id.parent_id,
                         status_code=e.status_code, role='openai')
                return []
            except openai.RateLimitError as e:
                _logger.warning(f"OPENAI: Run Ratelimit {e.status_code} {e.response}")
                self.log(f"OPENAI: Run Ratelimit {e.status_code} {e.response}", self.recipient_id.parent_id,
                         status_code=e.status_code, role='openai')
                return []
            except openai.APIStatusError as e:
                _logger.warning(f"OPENAI: Run Status error {e.status_code} {e.response}")
                self.log(f"OPENAI: Run Status error {e.status_code} {e.response}", self.recipient_id.parent_id,
                         status_code=e.status_code, role='openai', )
                return [{'role': 'assistant', 'content': f"OPENAI: Status error {e.status_code} {e.response}"}]

        msgs = []
        while True:
            # Wait for 5 seconds
            # Retrieve the run status
            run_status = client.beta.threads.runs.retrieve(
                thread_id=self.thread,
                run_id=self.run
            )

            self.log(f"{run_status.status=}", self.recipient_id.parent_id, role='run', )
            # If run is completed, get messages
            if run_status.status == 'completed':
                messages = client.beta.threads.messages.list(
                    thread_id=self.thread
                )
                _logger.warning(f"Completed: {messages=}")

                # Loop through messages and print content based on role
                for msg in messages.data:
                    self.log(' '.join([m.text.value for m in msg.content]), self.recipient_id.parent_id, msg.role)
                    if msg.run_id == self.run:
                        msgs.append({'role': msg.role, 'content': msg.content[0].text.value})
                    _logger.warning(f"{msg.id=} {msg.run_id=} {msg.role=}: {msg.content=}")
                self.run = None
                break
            elif run_status.status == 'requires_action':

                _logger.warning(f"Function calling")

                required_actions = run_status.required_action.submit_tool_outputs.model_dump()
                _logger.warning(f"{run_status.status=} {required_actions}")
                self.log(f"{run_status.status=} {required_actions=}", self.recipient_id.parent_id, role='run')
                tool_outputs = []

                for action in required_actions["tool_calls"]:
                    func_name = action['function']['name']
                    arguments = json.loads(action['function']['arguments'])
                    _logger.warning(f"{arguments=}")

                    if func_name == "get_stock_price":
                        output = self.get_stock_price(symbol=arguments['symbol'])
                        tool_outputs.append({
                            "tool_call_id": action['id'],
                            "output": output
                        })                    
                    else:
                        raise ValueError(f"Unknown function: {func_name}")

                _logger.warning("Submitting outputs back to the Assistant...")
                self.log(f"Submit tools outputs {tool_outputs=}", self.recipient_id.parent_id, role='run')
                client.beta.threads.runs.submit_tool_outputs(
                    thread_id=self.thread,
                    run_id=self.run,
                    tool_outputs=tool_outputs
                )

            else:
                _logger.warning(f"Waiting for the Assistant to process... {run_status.status=} {self.run=}")

            time.sleep(1)
        return msgs


    def _thread_unlink(self, client, channel):
        _logger.info(f"\033[1;35m M:OpenAI bot / F:openai_thread / C:OpenAIThread / _thread_unlink: Entered \033[0m")
        #_logger.warning("openai _thread_unlink"*10)
        if self.recipient_id.llm_type != "openai":
            return super(OpenAIThread, self)._thread_unlink(client, channel)
        return
        ##TODO Where Im is supposed to get the client form
        try:
            client.beta.assistants.delete(self.assistant)
        except openai.APIConnectionError as e:
            _logger.warning(f"OPENAI: Delete The server could not be reached {e.__cause__}")
        except openai.RateLimitError as e:
            _logger.warning(f"OPENAI: Delete Ratelimit {e.status_code} {e.response}")
        except openai.APIStatusError as e:
            _logger.warning(f"OPENAI: Delete Status error {e.status_code} {e.response}")
        self.recipient_id.openai_assistant = None

        return super(OpenAIThread, self)._thread_unlink(client, channel)


    def get_stock_price(self, symbol: str) -> float:
        _logger.info(f"\033[1;35m M:OpenAI bot / F:openai_thread / C:OpenAIThread / get_stock_price: Entered \033[0m")
        stock = yf.Ticker(symbol)
        price = stock.history(period="1d")['Close'].iloc[-1]
        return price
    
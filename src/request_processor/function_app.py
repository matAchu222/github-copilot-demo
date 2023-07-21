"""
This module is responsible for processing all incoming requests. It is triggered by a
message being added to the "request_open" queue. It then processes the request and
sends a message to the "request_processed" queue.
"""
import logging

import azure.functions as func

app = func.FunctionApp()


@app.function_name(name="request_processor")
@app.queue_trigger(
    arg_name="request_open",
    queue_name="request_open",
    connection="acnasgcopilotdemo-storageaccount",
)
@app.queue_output(
    arg_name="request_processed",
    queue_name="request_processed",
    connection="storageAccountConnectionString",
)
def process(request_open: func.QueueMessage, request_processed: func.Out[str]) -> None:
    """
    This function is triggered by a message being added to the "request_open" queue.
    It then processes the request and sends a message to the "request_processed" queue.
    """
    logging.info(
        "Python queue trigger function processed a queue item: %s",
        request_open.get_body().decode("utf-8"),
    )

    message = request_open.get_body().decode("utf-8") + " got processed"
    request_processed.set(message)

    logging.info("Message sent to request_processed queue: %s", message)

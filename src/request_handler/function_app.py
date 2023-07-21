"""
This is the entry point for the Azure Function App. It is responsible for
handling all incoming requests and routing them to the appropriate backend service.
"""
import logging

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.function_name(name="request_handler")
@app.route(route="submit")
def submit_request(req: func.HttpRequest) -> func.HttpResponse:
    """
    This function handles all incoming requests and prepares them for processing.
    """
    logging.info("Python HTTP trigger function processed a request.")

    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get("name")

    if name:
        message = f"Hello, {name}. This HTTP triggered function executed OK."
    else:
        message = "This HTTP triggered function executed successfully. Pass a name \
            in the query string or in the request body for a personalized response."

    return func.HttpResponse(message, status_code=200)


# @app.function_name(name="request_handler")
# @app.route(route="submit")
# @app.queue_output(
#     arg_name="request_open",
#     queue_name="request_open",
#     connection="storageAccountConnectionString",
# )
# def submit_request(
#     req: func.HttpRequest, request_processed: func.Out[str]
# ) -> func.HttpResponse:
#     """
#     This function handles all incoming requests and prepares them for processing.
#     """
#     logging.info("Python HTTP trigger function processed a request.")

#     name = req.params.get("name")
#     if not name:
#         try:
#             req_body = req.get_json()
#         except ValueError:
#             pass
#         else:
#             name = req_body.get("name")

#     if name:
#         message = f"Hello, {name}. This HTTP triggered function executed OK."
#     else:
#         message = "This HTTP triggered function executed successfully. Pass a name \
#             in the query string or in the request body for a personalized response."

#     request_processed.set(message)
#     return func.HttpResponse(message, status_code=200)

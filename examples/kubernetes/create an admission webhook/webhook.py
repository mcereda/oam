#!/usr/bin/env python3

from base64 import b64encode
from flask import Flask, request, jsonify
from jsonpatch import JsonPatch

admission_webhook = Flask(__name__)

labels = [
	"app.kubernetes.io/component",
	"app.kubernetes.io/name",
	"app.kubernetes.io/part-of",
	"app.kubernetes.io/version"
]

@admission_webhook.route('/validate', methods=['POST'])
def validate():
	info = request.get_json()
	for label in labels:
		try:
			info["request"]["object"]["metadata"]["labels"][label]
		except:
			return validation_response(info["request"]["uid"], False, f"missing required label '{label}'")
	return validation_response(info["request"]["uid"], True, "request validated successfully")
def validation_response(uid, allowed, message):
	return jsonify({
		"response": {
			"allowed": allowed,
			"status": {
				"message": message
			},
			"uid": uid
		}
	})

@admission_webhook.route('/mutate', methods=['POST'])
def mutate():
	info = request.get_json()
	return mutation_response(
		info["request"]["uid"],
		True,
		"adding label 'revised'",
		json_patch = JsonPatch([{
			"op": "add",
			"path": "/metadata/labels/revised",
			"value": "yes"
		}])
	)
def mutation_response(uid, allowed, message, json_patch):
	base64_patch = b64encode(json_patch.to_string().encode("utf-8")).decode("utf-8")
	return jsonify({
		"response": {
			"allowed": allowed,
			"status": {
				"message": message
			},
			"patchType": "JSONPatch",
			"patch": base64_patch,
			"uid": uid
		}
	})

if __name__ == '__main__':
	admission_webhook.run(host='0.0.0.0', port=8443, ssl_context=("/cert/cert.pem", "/cert/key.pem"))

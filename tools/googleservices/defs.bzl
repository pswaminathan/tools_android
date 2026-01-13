"""Rules to support Google services, e.g. Firebase Cloud Messaging."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:jvm.bzl", "jvm_maven_import_external")


_GMS_KEEP_CONTENT = """<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@string/common_google_play_services_unknown_issue,@string/default_web_client_id,@string/gcm_defaultSenderId,@string/google_api_key,@string/google_app_id,@string/google_crash_reporting_api_key,@string/google_storage_bucket,@string/project_id" />"""


def _google_services_xml_impl(ctx):
    package_name = ctx.attr.package_name
    google_services_json = ctx.file.google_services_json

    gms_values_file = ctx.actions.declare_file(
        "google_services_xml/%s/%s/res/values/values.xml" % (
            package_name,
            google_services_json.path.replace("/", "_")))
    res_keep_file = ctx.actions.declare_file(
        "google_services_xml/%s/%s/res/raw/%s_keep.xml" % (
            package_name,
            google_services_json.path.replace("/", "_"),
            package_name))

    ctx.actions.run(
        outputs = [gms_values_file],
        inputs = [google_services_json],
        executable = ctx.executable._generator,
        arguments = [package_name, google_services_json.path, gms_values_file.path],
        mnemonic = "GenerateGoogleServicesXml",
    )

    ctx.actions.write(
        output = res_keep_file,
        content = _GMS_KEEP_CONTENT,
        is_executable = False,
    )


    return [DefaultInfo(files = depset([gms_values_file, res_keep_file]))]

google_services_xml = rule(
    implementation = _google_services_xml_impl,
    attrs = {
        "package_name": attr.string(
            mandatory = True,
            doc = "The package name (or application ID) of the Android app.",
        ),
        "google_services_json": attr.label(
            mandatory = True,
            allow_single_file = [".json"],
            doc = "The google-services.json file.",
        ),
        "_generator": attr.label(
            default = "@tools_android//third_party/googleservices:GenerateGoogleServicesXml",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = """Creates Android resource XML for Google services.

    The XML is based on a google-services.json file.

    This rule assumes that the Android tools repository is named "tools_android"
    in the top-level project's WORKSPACE file.
    """,
)

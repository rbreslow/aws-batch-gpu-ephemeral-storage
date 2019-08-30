SHELL:=/bin/bash

plan:
	terraform init
	terraform plan \
		-var-file=aws-batch-gpu-ephemeral-storage.tfvars \
		-out=aws-batch-gpu-ephemeral-storage.tfplan

apply:
	terraform apply aws-batch-gpu-ephemeral-storage.tfplan

test-cpu:
	for i in {1..10}; \
	do \
		aws batch submit-job \
			--job-name "$${i}-test-cpu" \
			--job-queue queueRockyCPU \
			--job-definition test_cpu_job_definition; \
	done

test-gpu:
	aws batch submit-job \
		--job-name "1-test-gpu" \
		--job-queue queueRockyGPU \
		--job-definition test_gpu_job_definition

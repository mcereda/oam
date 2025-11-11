import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const iamRole: pulumi.Output<aws.iam.GetRoleResult> = aws.iam.getRoleOutput({
    name: 'SomeServiceRole',
});

// -----------------

/**
 * Base type for Step Function states.
 *
 * States are elements in a state machine.\
 * A state is referred to by its name, which can be any string, but which must be unique within the scope of the entire
 * state machine.
 *
 * States take input from their own invocation or a previous state.\
 * States can filter their input and manipulate the output that is sent to the next state.
 *
 * Refer <https://docs.aws.amazon.com/step-functions/latest/dg/workflow-states.html>.
 */
type StateMachineBaseState = {
    Type: string;
    Comment?: string;
    Next?: string;
    End?: boolean;
};

/**
 * Choice state.\
 * Enables conditional branching.
 *
 * Refer <https://docs.aws.amazon.com/step-functions/latest/dg/state-choice.html>.
 */
interface StateMachineChoiceState extends StateMachineBaseState {
    Type: "Choice";
    Choices: Record<string, any>[];
    Default: string;
};

/**
 * Branch type for Parallel states.\
 * Itself a smaller state machine.
 */
type StateMachineParallelBranch = {
    StartAt: string;
    States: Record<string, StateMachineStepState>;
}
/**
 * Parallel state.\
 * Runs other step states in parallel.
 *
 * Refer <https://docs.aws.amazon.com/step-functions/latest/dg/state-parallel.html>.
 */
interface StateMachineParallelState extends StateMachineBaseState {
    Type: "Parallel";
    Branches: StateMachineParallelBranch[];
};

/**
 * Task state.\
 * Runs a service integration or Lambda function.
 *
 * Refer <https://docs.aws.amazon.com/step-functions/latest/dg/state-task.html>.
 */
interface StateMachineTaskState extends StateMachineBaseState {
    Type: "Task";
    Resource: string;
    Arguments?: Record<string, any>;
    Output?: Record<string, any>;
};

/**
 * Wait state.\
 * Pauses execution for a fixed duration or until a specified time or date.
 *
 * Refer <https://docs.aws.amazon.com/step-functions/latest/dg/state-wait.html>.
 */
interface StateMachineWaitState extends StateMachineBaseState {
    Type: "Wait";
    Seconds?: number;
    Timestamp?: string;
};

/**
 * Union type for Step Function states.
 */
type StateMachineStepState =
    | StateMachineChoiceState
    | StateMachineParallelState
    | StateMachineTaskState
    | StateMachineWaitState;

/**
 * Generic State Machine definition.
 */
interface StateMachineDefinition {
    Comment?: string;
    QueryLanguage?: string;
    StartAt: string;
    States: Record<string, StateMachineStepState>;
};

// -----------------

const changeClonedDbInstancePassword: StateMachineTaskState = {
    Type: "Task",
    Resource: "arn:aws:states:::aws-sdk:rds:modifyDBInstance",
    Arguments: {
        DbInstanceIdentifier: "{% $states.input.ClonedDBInstance.DbInstanceIdentifier %}",
        MasterUserPassword: "some-Secur3-Password",
        ApplyImmediately: true,
    },
    End: true,
};

const checkClonedDbInstanceIsAvailable: StateMachineChoiceState = {
    Type: "Choice",
    Choices: [
        {
            Condition: "{% $states.input.ClonedDBInstance.DbInstanceStatus in ['available'] %}",
            Next: "ChangeClonedDBInstancePassword",
        },
    ],
    Default: "WaitForClonedDBInstanceNextCheck",
};

const createClonedDbInstance: StateMachineTaskState = {
    Type: "Task",
    Resource: "arn:aws:states:::aws-sdk:rds:restoreDBInstanceToPointInTime",
    Arguments: {
        SourceDBInstanceIdentifier: "{% $states.input.ExistingDBInstanceInfo.DbInstanceIdentifier %}",
        UseLatestRestorableTime: true,
        TargetDBInstanceIdentifier: "{% $join([$states.input.ExistingDBInstanceInfo.DbInstanceIdentifier, 'clone'], '-') %}",
        Engine: "postgres",
        MultiAZ: false,
        AvailabilityZone: "eu-west-1a",
        DbSubnetGroupName: "default",
        PubliclyAccessible: false,
        VpcSecurityGroupIds: [],
        DbParameterGroupName: "{% $states.input.ExistingDBInstanceInfo.DbParameterGroups[0].DbParameterGroupName %}",
        OptionGroupName: "{% $states.input.ExistingDBInstanceInfo.OptionGroupMemberships[0].OptionGroupName %}",
        StorageType: "gp3",
        DedicatedLogVolume: false,
        DbInstanceClass: "db.t4g.medium",
        DeletionProtection: false,
        AutoMinorVersionUpgrade: false,
    },
    Output: {
        ClonedDBInstance: "{% $states.result.DbInstance %}",
    },
    Next: "GetClonedDBInstanceState",
};

const getClonedDbInstanceState: StateMachineTaskState = {
    Type: "Task",
    Resource: "arn:aws:states:::aws-sdk:rds:describeDBInstances",
    Arguments: {
        DbInstanceIdentifier: "{% $states.input.ClonedDBInstance.DbInstanceIdentifier %}",
    },
    Output: {
        ClonedDBInstance: "{% $states.result.DbInstances[0] %}",
    },
    Next: "CheckClonedDBInstanceIsAvailable",
};

const getExistingDbInstanceInfo: StateMachineTaskState = {
    Type: "Task",
    Resource: "arn:aws:states:::aws-sdk:rds:describeDBInstances",
    Arguments: {
        DbInstanceIdentifier: "some-existing-rds-instance",
    },
    Output: {
        ExistingDBInstanceInfo: "{% $states.result.DbInstances[0] %}",
    },
    Next: "ParallelZone",
};

const waitForClonedDbInstanceNextCheck: StateMachineWaitState = {
    Type: "Wait",
    Seconds: 60,
    Next: "GetClonedDBInstanceState",
};

const parallelZone: StateMachineParallelState = {
    Type: "Parallel",
    Branches: [
        {
            StartAt: "CreateClonedDBInstance",
            States: {
                CreateClonedDBInstance: createClonedDbInstance,
                GetClonedDBInstanceState: getClonedDbInstanceState,
                CheckClonedDBInstanceIsAvailable: checkClonedDbInstanceIsAvailable,
                WaitForClonedDBInstanceNextCheck: waitForClonedDbInstanceNextCheck,
                ChangeClonedDBInstancePassword: changeClonedDbInstancePassword,
            },
        },
        // FIXME: another branch here
    ],
    End: true,
};

const stateMachineDefinition: StateMachineDefinition = {
    QueryLanguage: "JSONata",
    States: {
        GetExistingDBInstanceInfo: getExistingDbInstanceInfo,
        ParallelZone: parallelZone,
    },
    StartAt: "GetExistingDBInstanceInfo",
};
// pulumi.jsonStringify(stateMachineDefinition).apply(s => console.log(s))

const dbCloner_stateMachine: aws.sfn.StateMachine = new aws.sfn.StateMachine(
    'dbCloner',
    {
        name: 'DBCloner',
        roleArn: iamRole.arn,
        loggingConfiguration: {
            level: "OFF",
        },
        encryptionConfiguration: {
            type: "AWS_OWNED_KEY",
        },
        publish: false,
        definition: pulumi.jsonStringify(stateMachineDefinition),
    },
);

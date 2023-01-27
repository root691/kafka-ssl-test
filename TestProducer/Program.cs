using Confluent.Kafka;

namespace TestProducer;

public static class TestProducer
{
    private const string TopicName = "test-topic";

    private static Task CKafka()
    {
        var conf = new ProducerConfig
        {
            BootstrapServers = "kafka:9092",
            SecurityProtocol = SecurityProtocol.Ssl,
            EnableSslCertificateVerification = true,
            Debug = "all",
            SslKeystoreLocation = @"C:\Users\n.korneev\Documents\Git\kafka-ssl-test\secrets\client.keystore.p12",
            SslKeystorePassword = "mylovelyca",
            SslKeyPassword = "mylovelyca",
            SslCaLocation = "ca.crt"
        };

        Action<DeliveryReport<string, string>> handler = r =>
            Console.WriteLine(!r.Error.IsError
                ? $"Delivered message to {r.TopicPartitionOffset}"
                : $"Delivery Error: {r.Error.Reason}");

        using (var p = new ProducerBuilder<string, string>(conf).Build())
        {
            for (int i = 0; i < 100; ++i)
            {
                p.Produce(TopicName, new Message<string, string> { Key = "test", Value = i.ToString() }, handler);
            }

            p.Flush(TimeSpan.FromSeconds(10));
        }

        return Task.CompletedTask;
    }

    public static async Task Main()
    {
        await CKafka().ConfigureAwait(false);
    }
}
